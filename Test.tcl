# Create a new simulator
set ns [new Simulator]

# Set up the wireless channel
set channel [new Channel/WirelessChannel]

# Define the general operational parameters
set prop [new Propagation/TwoRayGround]
set netif [new Phy/WirelessPhy]
set mac [new Mac/802_11]
set ifq [new Queue/DropTail/PriQueue]
set ll [new LL]
set ant [new Antenna/OmniAntenna]
set god [new God]

# Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all-wireless $nf 500 500  ;# Define a 500x500 simulation area

# Define a 'finish' procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam out.nam &
    exit 0
}

# Create five wireless nodes (n0, n1, n2, n3, n4)
for {set i 0} {$i < 5} {incr i} {
    set n($i) [$ns node]
    $n($i) set X_ [expr 100 + ($i * 50)]   ;# Place nodes in a fixed pattern
    $n($i) set Y_ 250
    $n($i) set Z_ 0

    $n($i) random-motion 0  ;# Disable mobility

    # Set up wireless parameters for each node
    $n($i) set channel_ $channel
    $n($i) set prop_ $prop
    $n($i) set netif_ $netif
    $n($i) set mac_ $mac
    $n($i) set ifq_ $ifq
    $n($i) set ll_ $ll
    $n($i) set antenna_ $ant
    $n($i) set adhocRouting AODV
}

# Define the TCP connection (Node 3 → Node 4)
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n(3) $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $n(4) $sink
$ns connect $tcp $sink
$tcp set fid_ 1

# Setup FTP over TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# Setup a UDP connection (Node 1 → Node 3)
set udp [new Agent/UDP]
$ns attach-agent $n(1) $udp

set null [new Agent/Null]
$ns attach-agent $n(3) $null
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
$ns at 4.5 "$ns detach-agent $n(3) $tcp ; $ns detach-agent $n(4) $sink"

# Call the finish procedure after 5 seconds
$ns at 5.0 "finish"

# Print CBR details
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

# Run the simulation
$ns run
