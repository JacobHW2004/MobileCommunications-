# wrls1.tcl
# A 5-node example for ad-hoc simulation with AODV
# Modified based on original script by Dr. Idris Skloul Ibrahim

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
set tracefd     [open $val(rp)_trace_file_5_nodes.tr w]
set windowVsTime2 [open win.tr w] 
set namtrace    [open simwrls.nam w]    

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# Set up topography object
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

# Configure the nodes
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

# Create and configure nodes
for {set i 0} {$i < $val(nn)} { incr i } {
    set node_($i) [$ns node]    
}

# Provide initial location of mobile nodes
$node_(4) set X_ 100.0
$node_(4) set Y_ 200.0
$node_(4) set Z_ 0.0

$node_(0) set X_ 200.0
$node_(0) set Y_ 300.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 200.0
$node_(1) set Y_ 100.0
$node_(1) set Z_ 0.0

$node_(2) set X_ 300.0
$node_(2) set Y_ 200.0
$node_(2) set Z_ 0.0

$node_(3) set X_ 400.0
$node_(3) set Y_ 200.0
$node_(3) set Z_ 0.0


# Node Movements
#$ns at 10.0 "$node_(0) setdest 200.0 200.0 3.0"
#$ns at 15.0 "$node_(1) setdest 300.0 250.0 4.0"
#$ns at 20.0 "$node_(3) setdest 250.0 300.0 3.0"
#$ns at 25.0 "$node_(2) setdest 260.0 220.0 2.5"
#$ns at 30.0 "$node_(4) setdest 250.0 150.0 3.5"

# TCP connection between Node 0 and Node 1 through Node 4
set tcp [new Agent/TCP/Newreno]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns attach-agent $node_(3) $tcp
$ns attach-agent $node_(4) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 10.0 "$ftp start"

# Function to plot window size
proc plotWindow {tcpSource file} {
    global ns
    set time 0.01
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now+$time] "plotWindow $tcpSource $file"
}
$ns at 10.1 "plotWindow $tcp $windowVsTime2"

# Define node initial position in NAM
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
$ns at 150.01 "puts \"End simulation\" ; $ns halt"

proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    exec nam simwrls.nam &
    exit 0
}

$ns run
