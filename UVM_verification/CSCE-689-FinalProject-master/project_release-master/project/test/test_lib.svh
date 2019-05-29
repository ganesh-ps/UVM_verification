//=====================================================================
// Project: 4 core MESI cache design
// File Name: test_lib.svh
// Description: Base test class and list of tests
// Designers: Venky & Suru
//=====================================================================
//TODO: add your testcase files in here
`include "base_test.sv"
`include "read_miss_icache.sv"
`include "lru_replacement.sv"
`include "mesi_state.sv"
`include "random_mesi_state_transitions.sv"
`include "write_icache.sv"
`include "read_miss_dcache.sv"
`include "cache_reads0.sv"
`include "cache_reads1.sv"
`include "cache_reads2.sv"
`include "cache_reads3.sv"
`include "cache_writes0.sv"
`include "cache_writes1.sv"
`include "cache_writes2.sv"
`include "cache_writes3.sv"
`include "read_miss_followed_by_write0.sv"
`include "read_miss_followed_by_write1.sv"
`include "read_miss_followed_by_write2.sv"
`include "read_miss_followed_by_write3.sv"
`include "read_write_directed0.sv"
`include "read_write_directed1.sv"
`include "read_write_directed2.sv"
`include "read_write_directed3.sv"
`include "cache_d_random.sv"
`include "cache_reads_random.sv"
`include "cache_writes_random.sv"

