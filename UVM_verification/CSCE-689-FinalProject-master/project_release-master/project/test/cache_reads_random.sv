
class cache_reads_random extends base_test;

    //component macro
    `uvm_component_utils(cache_reads_random)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", cache_reads_random_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing cache_reads_random test" , UVM_LOW)
    endtask: run_phase

endclass : cache_reads_random



class cache_reads_random_seq extends base_vseq;
    //object macro
    `uvm_object_utils(cache_reads_random_seq)

    cpu_transaction_c trans;

    //constructor
    function new (string name="cache_reads_random_seq");
        super.new(name);
    endfunction : new

    virtual task body();

    repeat(10)
    begin
    `uvm_do_on_with(trans, p_sequencer.cpu_seqr[mp], {request_type == READ_REQ;})
    end

    endtask
        
endclass

