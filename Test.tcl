# A 5-node wireless ad-hoc simulation with AODV,
# reconfigured so that:
#   - Node 4 connects to Node 0 and Node 1,
#   - Node 0 and Node 1 connect to Node 2,
#   - Node 2 connects to Node 3.
# Original script by Dr. Idris Skloul Ibrahim (modified version)

# Define options
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             5                          ;# number of mobile nodes
set val(rp)             AODV                       ;# AODV routing protocol
set val(x)              500                        ;# X dimension of topography
set val(y)              400                        ;# Y dimension of topography  
set val(stop)           150                        ;# Simulation end time

set ns          [new Simulator]
set tracefd     [open $val(rp)_trace_file_custom.tr w]
set windowVsTime2 [open win.tr w] 
set namtrace    [open simwrls_custom.nam w]    

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# Set up topography object
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

# Configure the nodes with wireless parameters
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channelType $val(chan) \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace ON

# Create and configure 5 nodes
for {set i 0} {$i < $val(nn)} { incr i } {
    set node_($i) [$ns node]    
}

# Revert to the original node positions:
# Node 4 at (100, 200, 0)
$node_(4) set X_ 100.0
$node_(4) set Y_ 200.0
$node_(4) set Z_ 0.0

# Node 0 at (200, 300, 0)
$node_(0) set X_ 200.0
$node_(0) set Y_ 300.0
$node_(0) set Z_ 0.0

# Node 1 at (200, 100, 0)
$node_(1) set X_ 200.0
$node_(1) set Y_ 100.0
$node_(1) set Z_ 0.0

# Node 2 at (300, 200, 0)
$node_(2) set X_ 300.0
$node_(2) set Y_ 200.0
$node_(2) set Z_ 0.0

# Node 3 at (400, 200, 0)
$node_(3) set X_ 400.0
$node_(3) set Y_ 200.0
$node_(3) set Z_ 0.0

# Define a procedure to plot TCP window size over time
proc plotWindow {tcpSource file} {
    global ns
    set time 0.01
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now+$time] "plotWindow $tcpSource $file"
}

# --- Setup multiple TCP/FTP connections between nodes ---
# The connections are as follows:
#   Flow 1: Node4 -> Node0
#   Flow 2: Node4 -> Node1
#   Flow 3: Node0 -> Node2
#   Flow 4: Node1 -> Node2
#   Flow 5: Node2 -> Node3

# Helper procedure to setup a TCP/FTP flow from source node to destination node
proc setupTCPFlow {src dst startTime fid} {
    global ns node_ windowVsTime2
    set tcp [new Agent/TCP/Newreno]
    $tcp set class_ 2
    set sink [new Agent/TCPSink]
    $ns attach-agent $src $tcp
    $ns attach-agent $dst $sink
    $ns connect $tcp $sink
    $tcp set fid_ $fid
    set ftp [new Application/FTP]
    $ftp attach-agent $tcp
    $ns at $startTime "$ftp start"
    # Optionally monitor the TCP window (only for the first flow here)
    if {$fid == 1} {
        $ns at [expr $startTime+0.1] "plotWindow $tcp $windowVsTime2"
    }
}

# Setting up the flows with staggered start times
setupTCPFlow $node_(4) $node_(0) 10.0 1    ;# Node4 -> Node0
setupTCPFlow $node_(4) $node_(1) 12.0 2    ;# Node4 -> Node1
setupTCPFlow $node_(0) $node_(2) 14.0 3    ;# Node0 -> Node2
setupTCPFlow $node_(1) $node_(2) 16.0 4    ;# Node1 -> Node2
setupTCPFlow $node_(2) $node_(3) 18.0 5    ;# Node2 -> Node3

# Define node initial positions in NAM for visualization
for {set i 0} {$i < $val(nn)} { incr i } {
    $ns initial_node_pos $node_($i) 30
}

# Tell nodes when simulation ends
for {set i 0} {$i < $val(nn)} { incr i } {
    $ns at $val(stop) "$node_($i) reset"
}

# Ending NAM and the simulation
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at [expr $val(stop)+0.01] "puts \"End simulation\" ; $ns halt"

proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    exec nam simwrls_custom.nam &
    exit 0
}

$ns run
