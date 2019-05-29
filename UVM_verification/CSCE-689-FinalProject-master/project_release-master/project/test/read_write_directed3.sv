
class read_write_directed3 extends base_test;

    //component macro
    `uvm_component_utils(read_write_directed3)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", read_write_directed3_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing read_write_directed3 test" , UVM_LOW)
    endtask: run_phase

endclass : read_write_directed3



class read_write_directed3_seq extends base_vseq;
    //object macro
    `uvm_object_utils(read_write_directed3_seq)

    cpu_transaction_c trans;

    //constructor
    function new (string name="read_write_directed3_seq");
        super.new(name);
    endfunction : new

    virtual task body();
`uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC;data == 32'h0000_FFCC; address == 32'h4004_1111 ;})

   `uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC;data == 32'hFFFF_AE1C; address == 32'h4004_1110 ;})
    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == 32'h4004_1111 ;})

    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == 32'h4004_1110 ;})

    endtask
        
endclass
