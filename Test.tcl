# Create a new simulator
set ns [new Simulator]

# Define the wireless trace file
set tracefile [open out.tr w]
$ns trace-all $tracefile

# Define the NAM file for visualization
set namfile [open out.nam w]
$ns namtrace-all-wireless $namfile 500 500  ;# Wireless scenario with 500x500 area

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam out.nam &
    exit 0
}

# Define wireless channel, propagation model, and MAC layer
set channel [new Channel/WirelessChannel]
set prop [new Propagation/TwoRayGround]
set netif [new Phy/WirelessPhy]
set mac [new Mac/802_11]
set queue [new Queue/DropTail/PriQueue]
set ll [new LL]
set antenna [new Antenna/OmniAntenna]
set ifq [new Queue/DropTail/PriQueue]

# Create nodes (n0 to n4) with wireless capabilities
set nodes {}
for {set i 0} {$i < 5} {incr i} {
    set node [$ns node]
    $node set X_ [expr $i * 100]   ;# Spread nodes evenly
    $node set Y_ [expr 250]        ;# Keep nodes at the same Y position
    $node set Z_ 0
    $node set channel_ $channel
    $node set propInstance_ $prop
    $node set netif_ $netif
    $node set mac_ $mac
    $node set ifq_ $ifq
    $node set ll_ $ll
    $node set antenna_ $antenna
    $node set adhocRouting AODV    ;# Use AODV routing for ad-hoc communication
    lappend nodes $node
}

# Extract nodes from the list
set n0 [lindex $nodes 0]
set n1 [lindex $nodes 1]
set n2 [lindex $nodes 2]
set n3 [lindex $nodes 3]
set n4 [lindex $nodes 4]

# Setup a TCP connection (Node 3 → Node 4)
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n3 $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

# Setup FTP over TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# Setup a UDP connection (Node 1 → Node 3)
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp

set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

# Setup CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false

# Schedule events for the CBR and FTP agents
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"

# Detach TCP and Sink agents
$ns at 4.5 "$ns detach-agent $n3 $tcp ; $ns detach-agent $n4 $sink"

# Call the finish procedure after 5 seconds
$ns at 5.0 "finish"

# Print CBR details
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

# Run the simulation
$ns run
