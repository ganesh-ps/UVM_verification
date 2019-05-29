//=====================================================================
// Project: 4 core MESI cache design
// File Name: system_bus_interface.sv
// Description: Basic system bus interface including arbiter
// Designers: Venky & Suru
//=====================================================================

interface system_bus_interface(input clk);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter DATA_WID_LV1        = `DATA_WID_LV1       ;
    parameter ADDR_WID_LV1        = `ADDR_WID_LV1       ;
    parameter NO_OF_CORE            = 4;

    wire [DATA_WID_LV1 - 1 : 0] data_bus_lv1_lv2     ;
    wire [ADDR_WID_LV1 - 1 : 0] addr_bus_lv1_lv2     ;
    wire                        bus_rd               ;
    wire                        bus_rdx              ;
    wire                        lv2_rd               ;
    wire                        lv2_wr               ;
    wire                        lv2_wr_done          ;
    wire                        cp_in_cache          ;
    wire                        data_in_bus_lv1_lv2  ;

    wire                        shared               ;
    wire                        all_invalidation_done;
    wire                        invalidate           ;

    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_gnt_proc ;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_req_proc ;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_gnt_snoop;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_req_snoop;
    logic                       bus_lv1_lv2_gnt_lv2  ;
    logic                       bus_lv1_lv2_req_lv2  ;

//Assertions
//property that checks that signal_1 is asserted in the previous cycle of signal_2 assertion
    property prop_sig1_before_sig2(signal_1,signal_2);
    @(posedge clk)
        signal_2 |-> $past(signal_1);
    endproperty

//ASSERTION1: lv2_wr_done should not be asserted without lv2_wr being asserted in previous cycle
    
    assert_lv2_wr_done: assert property (prop_sig1_before_sig2(lv2_wr,lv2_wr_done))
    else
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_wr_done Failed: lv2_wr not asserted before lv2_wr_done goes high"))

//TODO: Add assertions at this interface
//There are atleast 20 such assertions. Add as many as you can!!

//ASSERTION2
	property wr_wr_done;
	@(posedge clk)
		$rose(lv2_wr) |=> ##[0:$]$rose(lv2_wr_done); 
	endproperty
	
	assert_wr_wr_done: assert property(wr_wr_done)
	else
	`uvm_error("system_bus_interface",$sformatf("Assertion assert_wr_wr_done Failed: lv2_wr_done not asserted after lv2_wr was asserted"))


//ASSERTION3
	property invalidate_invalidation_done;
	@(posedge clk)
		$rose(invalidate) |=> ##[1:$] $rose(all_invalidation_done);
	endproperty
	
	assert_invalidate_invalidation_done: assert property(invalidate_invalidation_done)
	else
	`uvm_error("system_bus_interface",$sformatf("Assertion assert_invalidate_invalidation_done Failed:all_invalidation_done not asserted after invalidate was asserted"))

//ASSERTION4
 	property lv2_rd_data;
        @(posedge clk)
		$rose(lv2_rd) |-> ##[1:$] (|data_bus_lv1_lv2 );
	endproperty
	
	assert_lv2_rd_data: assert property(lv2_rd_data)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_rd_data Failed:data not available in data_bus_lv1_lv2 after lv2_rd was asserted"))

//ASSERTION5
        property data_in_bus_data;
        @(posedge clk)
                $rose(data_in_bus_lv1_lv2) |-> ##[1:$] (|data_bus_lv1_lv2 );
        endproperty

        assert_data_in_bus_data: assert property(data_in_bus_data)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_data_in_bus_data Failed:data not available in data_bus_lv1_lv2 after data_in_bus_lv1_lv2 was asserted"))

//ASSERTION6: all_invalidation_done should be asserted for single cycle

 	property all_invalidation_done_single_cycle;
        @(posedge clk)
                $rose(all_invalidation_done) |=> $fell(all_invalidation_done);
        endproperty

        assert_all_invalidation_done_single_cycle: assert property(all_invalidation_done_single_cycle)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion all_invalidation_done_single_cycle Failed:all_invalidation_done not asserted for single clock cycle"))


//ASSERTION7: 
	property prop_simult_bus_rd_rdx;
	@(posedge clk)
		not(bus_rd && bus_rdx);
	endproperty

	assert_prop_simult_bus_rd_rdx: assert property(prop_simult_bus_rd_rdx)
	else
	`uvm_error("system_bus_interface",$sformatf("Assertion assert_prop_simult_bus_rd_rdx Failed: bus_rd and bus_rdx asserted simultaneously"))
	
//ASSERTION8
	property bus_rd_req_snoop;
	@(posedge clk)
		$rose(bus_rd) |=> ##[0:$]$rose(|bus_lv1_lv2_req_snoop);
	endproperty

	assert_bus_rd_req_snoop: assert property(bus_rd_req_snoop)
	else
	`uvm_error("system_bus_interface",$sformatf("Assertion assert_bus_rd_req_snoop Failed: no snoop request asserted after bus_rd asserted"))

//ASSERTION9

	property bus_rdx_req_snoop;
        @(posedge clk)
                $rose(bus_rdx) |=>##[0:$] (|bus_lv1_lv2_req_snoop);
        endproperty

        assert_bus_rdx_req_snoop: assert property(bus_rdx_req_snoop)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_bus_rdx_req_snoop Failed: no snoop request asserted after bus_rdx asserted"))
	
//ASSERTION10
	property cp_in_cache_req_snoop;
	@(posedge clk)
                $rose(cp_in_cache) |=> ##[0:$] $rose(|bus_lv1_lv2_req_snoop);
        endproperty

        assert_cp_in_cache_req_snoop: assert property(cp_in_cache_req_snoop)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_cp_in_cache_req_snoop Failed: no snoop request asserted after cp_in_cache asserted"))

//ASSERTION11

	property cp_in_cache_shared;
        @(posedge clk)
                $rose(shared) |=> ##[0:$]$rose(cp_in_cache);
        endproperty

        assert_cp_in_cache_shared: assert property(cp_in_cache_shared)
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_cp_in_cache_shared Failed: shared asserted without cp_in_cache asserted"))

//Req_gnt_property
	property req_gnt(req,gnt);
	@(posedge clk)
		$rose(req) |=> ##[0:$]$rose(gnt);
	endproperty
//ASSERTION12
	assert_proc_req_gnt_0: assert property(req_gnt(bus_lv1_lv2_req_proc[0],bus_lv1_lv2_gnt_proc[0]))
	else
	`uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_req_gnt_0 Failed: bus_lv1_lv2_gnt_proc[0] not asserted after bus_lv1_lv2_req_proc[0] was asserted"))

	assert_proc_req_gnt_1: assert property(req_gnt(bus_lv1_lv2_req_proc[1],bus_lv1_lv2_gnt_proc[1]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_req_gnt_1 Failed: bus_lv1_lv2_gnt_proc[1] not asserted after bus_lv1_lv2_req_proc[1] was asserted"))

	assert_proc_req_gnt_2: assert property(req_gnt(bus_lv1_lv2_req_proc[2],bus_lv1_lv2_gnt_proc[2]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_req_gnt_2 Failed: bus_lv1_lv2_gnt_proc[2] not asserted after bus_lv1_lv2_req_proc[2] was asserted"))

	assert_proc_req_gnt_3: assert property(req_gnt(bus_lv1_lv2_req_proc[3],bus_lv1_lv2_gnt_proc[3]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_req_gnt_3 Failed: bus_lv1_lv2_gnt_proc[3] not asserted after bus_lv1_lv2_req_proc[3] was asserted"))

//ASSERTION13
	 assert_snoop_req_gnt_0: assert property(req_gnt(bus_lv1_lv2_req_snoop[0],bus_lv1_lv2_gnt_snoop[0]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_req_gnt_0 Failed: bus_lv1_lv2_gnt_snoop[0] not asserted after bus_lv1_lv2_req_snoop[0] was asserted"))

        assert_snoop_req_gnt_1: assert property(req_gnt(bus_lv1_lv2_req_snoop[1],bus_lv1_lv2_gnt_snoop[1]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_req_gnt_1 Failed: bus_lv1_lv2_gnt_snoop[1] not asserted after bus_lv1_lv2_req_snoop[1] was asserted"))

        assert_snoop_req_gnt_2: assert property(req_gnt(bus_lv1_lv2_req_snoop[2],bus_lv1_lv2_gnt_snoop[2]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_req_gnt_2 Failed: bus_lv1_lv2_gnt_snoop[2] not asserted after bus_lv1_lv2_req_snoop[2] was asserted"))

        assert_snoop_req_gnt_3: assert property(req_gnt(bus_lv1_lv2_req_snoop[3],bus_lv1_lv2_gnt_snoop[3]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_req_gnt_3 Failed: bus_lv1_lv2_gnt_snoop[3] not asserted after bus_lv1_lv2_req_snoop[3] was asserted"))

//ASSERTION14 
	 assert_lv2_req_gnt: assert property(req_gnt(bus_lv1_lv2_req_lv2,bus_lv1_lv2_gnt_lv2))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_req_gnt Failed: bus_lv1_lv2_gnt_lv2 not asserted after bus_lv1_lv2_req_lv2 was asserted"))


//No gnt without req
	property no_gnt_without_req(req,gnt);
	@(posedge clk)
		$rose(gnt) |-> ##[0:$]$past(req);
	endproperty

//ASSERTION15
        assert_proc_no_gnt_without_req_0: assert property(no_gnt_without_req(bus_lv1_lv2_req_proc[0],bus_lv1_lv2_gnt_proc[0]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_no_gnt_without_req_0 Failed: bus_lv1_lv2_gnt_proc[0] asserted without bus_lv1_lv2_req_proc[0] being asserted"))

	assert_proc_no_gnt_without_req_1: assert property(no_gnt_without_req(bus_lv1_lv2_req_proc[1],bus_lv1_lv2_gnt_proc[1]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_no_gnt_without_req_1 Failed: bus_lv1_lv2_gnt_proc[1] asserted without bus_lv1_lv2_req_proc[1] being asserted"))
	
	assert_proc_no_gnt_without_req_2: assert property(no_gnt_without_req(bus_lv1_lv2_req_proc[2],bus_lv1_lv2_gnt_proc[2]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_no_gnt_without_req_2 Failed: bus_lv1_lv2_gnt_proc[2] asserted without bus_lv1_lv2_req_proc[2] being asserted"))
	
	assert_proc_no_gnt_without_req_3: assert property(no_gnt_without_req(bus_lv1_lv2_req_proc[3],bus_lv1_lv2_gnt_proc[3]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_proc_no_gnt_without_req_3 Failed: bus_lv1_lv2_gnt_proc[3] asserted without bus_lv1_lv2_req_proc[3] being asserted"))
        


//ASSERTION16
        assert_snoop_no_gnt_without_req_0: assert property(no_gnt_without_req(bus_lv1_lv2_req_snoop[0],bus_lv1_lv2_gnt_snoop[0]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_no_gnt_without_req_0 Failed: bus_lv1_lv2_gnt_snoop[0] asserted without bus_lv1_lv2_req_snoop[0]"))

	assert_snoop_no_gnt_without_req_1: assert property(no_gnt_without_req(bus_lv1_lv2_req_snoop[1],bus_lv1_lv2_gnt_snoop[1]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_no_gnt_without_req_1 Failed: bus_lv1_lv2_gnt_snoop[1] asserted without bus_lv1_lv2_req_snoop[1]"))

	assert_snoop_no_gnt_without_req_2: assert property(no_gnt_without_req(bus_lv1_lv2_req_snoop[2],bus_lv1_lv2_gnt_snoop[2]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_no_gnt_without_req_2 Failed: bus_lv1_lv2_gnt_snoop[2] asserted without bus_lv1_lv2_req_snoop[2]"))

	assert_snoop_no_gnt_without_req_3: assert property(no_gnt_without_req(bus_lv1_lv2_req_snoop[3],bus_lv1_lv2_gnt_snoop[3]))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_snoop_no_gnt_without_req_3 Failed: bus_lv1_lv2_gnt_snoop[3] asserted without bus_lv1_lv2_req_snoop[3]"))


//ASSERTION17
         assert_lv2_no_gnt_without_req: assert property(no_gnt_without_req(bus_lv1_lv2_req_lv2,bus_lv1_lv2_gnt_lv2))
        else
        `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_no_gnt_without_req Failed: bus_lv1_lv2_gnt_lv2 asserted without bus_lv1_lv2_req_lv2"))


endinterface
