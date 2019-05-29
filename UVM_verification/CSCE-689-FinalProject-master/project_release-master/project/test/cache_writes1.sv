


class cache_writes1 extends base_test;

    //component macro
    `uvm_component_utils(cache_writes1)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", cache_writes1_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing cache_writes1 test" , UVM_LOW)
    endtask: run_phase

endclass : cache_writes1



class cache_writes1_seq extends base_vseq;
    //object macro
    `uvm_object_utils(cache_writes1_seq)

    cpu_transaction_c trans;

    //constructor
    function new (string name="cache_writes1_seq");
        super.new(name);
    endfunction : new

    virtual task body();

    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC;data == 32'h1111_1111; address == 32'h4004_4400 ;})
    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; data == 32'h1111_0000;address ==32'h4004_0001 ;})
    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; data == 32'h1111_FFFF;address == 32'h4444_1000 ;})

   `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; data == 32'hFFFF_1111;address == 32'h4444_1010 ;})


    endtask
        
endclass
