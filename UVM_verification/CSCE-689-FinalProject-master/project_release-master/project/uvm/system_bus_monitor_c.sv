//=====================================================================
// Project: 4 core MESI cache design
// File Name: system_bus_monitor_c.sv
// Description: system bus monitor component
// Designers: Venky & Suru
//=====================================================================

`include "sbus_packet_c.sv"

class system_bus_monitor_c extends uvm_monitor;
    //component macro
    `uvm_component_utils(system_bus_monitor_c)

    uvm_analysis_port #(sbus_packet_c) sbus_out;
    sbus_packet_c       s_packet;

    //Covergroup to monitor all the points within sbus_packet
    covergroup cover_sbus_packet;
        option.per_instance = 1;
        option.name = "cover_system_bus";
        REQUEST_TYPE: coverpoint  s_packet.bus_req_type;
        REQUEST_PROCESSOR: coverpoint s_packet.bus_req_proc_num;
        REQUEST_ADDRESS: coverpoint s_packet.req_address{
            option.auto_bin_max = 20;
        }
        READ_DATA: coverpoint s_packet.rd_data{
            option.auto_bin_max = 20;
        }
        //TODO: Add coverage for other fields of sbus_mon_packet
	
	REQUEST_SNOOP: coverpoint  s_packet.bus_req_snoop;
        REQUEST_SERVICEDBY: coverpoint  s_packet.req_serviced_by;
        REQUEST_CPINCACHE: coverpoint  s_packet.cp_in_cache;
        REQUEST_ISSHARED: coverpoint  s_packet.shared;
        REQUEST_SNOOP_WRITE: coverpoint s_packet.snoop_wr_req_flag;
	REQUEST_SERVICEDTIME: coverpoint  s_packet.service_time
	{
		option.auto_bin_max = 20;
	}
        
	WRITE_DATA_SNOOP: coverpoint s_packet.wr_data_snoop 
	{
		option.auto_bin_max = 20;
	}
	EVICT_DIRTY_BLK_ADDR : coverpoint s_packet.proc_evict_dirty_blk_addr 
	{
		option.auto_bin_max = 20;
	}
	EVICT_DIRTY_BLK_DATA : coverpoint s_packet.proc_evict_dirty_blk_data
	{
		option.auto_bin_max = 20;
	}
	EVICT_DIRTY_BLK_FLAG: coverpoint s_packet.proc_evict_dirty_blk_flag;

        //cross coverage
        //ensure each processor has read miss, write miss, invalidate, etc.
        X_PROC__REQ_TYPE: cross REQUEST_TYPE, REQUEST_PROCESSOR;
        X_PROC__ADDRESS: cross REQUEST_PROCESSOR, REQUEST_ADDRESS;
        X_PROC__DATA: cross REQUEST_PROCESSOR, READ_DATA;
        
	//TODO: Add relevant cross coverage (examples shown above)
	
	X_CPINCACHE__SNOOPREQ: cross REQUEST_CPINCACHE, REQUEST_SNOOP;
        X_SNOOPREQ__SERVICED: cross REQUEST_SNOOP, REQUEST_SERVICEDBY;
	X_PROC__EVICT_DIRTY_FLAG: cross  REQUEST_PROCESSOR, EVICT_DIRTY_BLK_FLAG;
	X_REQ_TYPE__EVICT_DIRTY_FLAG: cross REQUEST_TYPE, EVICT_DIRTY_BLK_FLAG;
	X_REQ_TYPE__SERVICE_TIME: cross REQUEST_TYPE, REQUEST_SERVICEDTIME;
	X_PROC__REQ_TYPE__SNOOPREQ: cross REQUEST_PROCESSOR, REQUEST_TYPE,REQUEST_SNOOP;
	X_PROC__SNOOP_WRITE_REQ: cross REQUEST_PROCESSOR, REQUEST_SNOOP_WRITE;
	X_PROC__WRITE_DATA_SNOOP: cross REQUEST_PROCESSOR, WRITE_DATA_SNOOP;
	X_SHARED__WRITEREQSNOOP: cross REQUEST_ISSHARED, REQUEST_SNOOP_WRITE;
	X_WRTIEREQSNOOP__WRITEDATASNOOP: cross REQUEST_SNOOP_WRITE, WRITE_DATA_SNOOP;
	X_PROC__EVICTADDRS: cross REQUEST_PROCESSOR, EVICT_DIRTY_BLK_ADDR;
	X_PROC__EVICTDATA: cross REQUEST_PROCESSOR, EVICT_DIRTY_BLK_DATA;
	X_PROC__SHARED: cross REQUEST_PROCESSOR, REQUEST_ISSHARED;


    endgroup

    // Virtual interface of used to observe system bus interface signals
    virtual interface system_bus_interface vi_sbus_if;

    //constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
        sbus_out = new("sbus_out", this);
        this.cover_sbus_packet = new();
    endfunction : new

    //UVM build phase ()
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // throw error if virtual interface is not set
        if (!uvm_config_db#(virtual system_bus_interface)::get(this, "","v_sbus_if", vi_sbus_if))
            `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vi_sbus_if"})
    endfunction: build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "RUN Phase", UVM_LOW)
        forever begin
        //TODO: Code for the system bus monitor is minimal!
        //Add code to observe other cases
        //Add code for dirty block eviction
        //Snoop requests, service time, etc
            // trigger point for creating the packet
            @(posedge (|vi_sbus_if.bus_lv1_lv2_gnt_proc));
            `uvm_info(get_type_name(), "Packet creation triggered", UVM_LOW)
            s_packet = sbus_packet_c::type_id::create("s_packet", this);
	    // wait for assertion of either bus_rd, bus_rdx or invalidate before monitoring other bus activities
            // lv2_rd for I-cache cases, lv2_wr for dirty block eviction
	    @(posedge(vi_sbus_if.lv2_wr | vi_sbus_if.bus_rd | vi_sbus_if.bus_rdx | vi_sbus_if.invalidate | vi_sbus_if.lv2_rd));
  	    if(vi_sbus_if.lv2_wr)
	    begin
                 s_packet.proc_evict_dirty_blk_flag = 1'b1;
                 s_packet.proc_evict_dirty_blk_addr = vi_sbus_if.addr_bus_lv1_lv2;
                 s_packet.proc_evict_dirty_blk_data = vi_sbus_if.data_bus_lv1_lv2;
	         @(posedge(vi_sbus_if.bus_rd | vi_sbus_if.bus_rdx | vi_sbus_if.invalidate | vi_sbus_if.lv2_rd));
            end		
	    fork
                begin: cp_in_cache_check
                    // check for cp_in_cache assertion
                    @(posedge vi_sbus_if.cp_in_cache) s_packet.cp_in_cache = 1;
                end : cp_in_cache_check
                begin: shared_check
                    // check for shared signal assertion when data_in_bus_lv1_lv2 is also high
                    wait(vi_sbus_if.shared & vi_sbus_if.data_in_bus_lv1_lv2) s_packet.shared = 1;
                end : shared_check
            join_none

            // bus request type
            if (vi_sbus_if.bus_rd === 1'b1)
                s_packet.bus_req_type = BUS_RD;
	    if (vi_sbus_if.bus_rdx === 1'b1)
		s_packet.bus_req_type = BUS_RDX;
	    if (vi_sbus_if.invalidate === 1'b1)
		s_packet.bus_req_type = INVALIDATE;
            if (vi_sbus_if.lv2_rd === 1'b1 && vi_sbus_if.addr_bus_lv1_lv2 < 32'h4000_0000) 
                s_packet.bus_req_type = ICACHE_RD;
	
            // proc which requested the bus access
            case (1'b1)
                vi_sbus_if.bus_lv1_lv2_gnt_proc[0]: s_packet.bus_req_proc_num = REQ_PROC0;
                vi_sbus_if.bus_lv1_lv2_gnt_proc[1]: s_packet.bus_req_proc_num = REQ_PROC1;
                vi_sbus_if.bus_lv1_lv2_gnt_proc[2]: s_packet.bus_req_proc_num = REQ_PROC2;
                vi_sbus_if.bus_lv1_lv2_gnt_proc[3]: s_packet.bus_req_proc_num = REQ_PROC3;
            endcase
  
            // address requested
            s_packet.req_address = vi_sbus_if.addr_bus_lv1_lv2;

            // fork and call tasks
            fork: update_info

	    // Proc which Requested for Snoop access
	        begin: snoop_access_check
		    @(posedge(|vi_sbus_if.bus_lv1_lv2_req_snoop))
	      		s_packet.bus_req_snoop = vi_sbus_if.bus_lv1_lv2_req_snoop;
                end: snoop_access_check

                // to determine which of snoops or L2 serviced read miss
                begin: req_service_check
                    if (s_packet.bus_req_type == BUS_RD || s_packet.bus_req_type == BUS_RDX || s_packet.bus_req_type == ICACHE_RD )
                    begin
                        @(posedge vi_sbus_if.data_in_bus_lv1_lv2);
                        `uvm_info(get_type_name(), "Bus read or bus readX successful", UVM_LOW)
                        s_packet.rd_data = vi_sbus_if.data_bus_lv1_lv2;
                        // check which had grant asserted
                        case (1'b1)
                            vi_sbus_if.bus_lv1_lv2_gnt_snoop[0]: s_packet.req_serviced_by = SERV_SNOOP0;
                            vi_sbus_if.bus_lv1_lv2_gnt_snoop[1]: s_packet.req_serviced_by = SERV_SNOOP1;
                            vi_sbus_if.bus_lv1_lv2_gnt_snoop[2]: s_packet.req_serviced_by = SERV_SNOOP2;
                            vi_sbus_if.bus_lv1_lv2_gnt_snoop[3]: s_packet.req_serviced_by = SERV_SNOOP3;
                            vi_sbus_if.bus_lv1_lv2_gnt_lv2     : s_packet.req_serviced_by = SERV_L2;
                        endcase
                    end
		end: req_service_check
		
		begin: snoop_req_check
			if((s_packet.bus_req_type == BUS_RD)||(s_packet.bus_req_type == BUS_RDX))
			begin
			@(posedge vi_sbus_if.lv2_wr);
				if(vi_sbus_if.cp_in_cache)
				begin
        	                s_packet.snoop_wr_req_flag = 1'b1;
				s_packet.wr_data_snoop = vi_sbus_if.data_bus_lv1_lv2;
				end
	          	end
		end: snoop_req_check

            join_none : update_info

	    // wait until request is processed and soend data
            @(negedge vi_sbus_if.bus_lv1_lv2_req_proc[0] or negedge vi_sbus_if.bus_lv1_lv2_req_proc[1] or negedge vi_sbus_if.bus_lv1_lv2_req_proc[2] or negedge vi_sbus_if.bus_lv1_lv2_req_proc[3]);

            `uvm_info(get_type_name(), "Packet to be written", UVM_LOW)

            // disable all spawned child processes from fork
            disable fork;

            // write into scoreboard after population of the packet fields
            sbus_out.write(s_packet);
            cover_sbus_packet.sample();
        end
    endtask : run_phase

endclass : system_bus_monitor_c
