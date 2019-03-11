import sys
import re
import numpy as np
import matplotlib.pyplot as plt

FILENAME_REGEX = "(?P<loss>0\.[0-9]+)\.out"
SECS_REGEX = "(?P<min>[0-9]+):(?P<secs>[0-9][0-9].[0-9]+)"
REGEX = ".*?%s.*?%s" % (FILENAME_REGEX, SECS_REGEX)

def extract_data(filename, protocol, regex, file_size):
    assert protocol in filename

    f = open(filename, 'r')

    loss_to_tput = {}
    for line in f:
        match = re.search(regex, line)
        total_time = 60*int(match.group("min")) + float(match.group("secs"))
        loss_to_tput[100*float(match.group("loss"))] = convert_secs_to_mbps(file_size, total_time)
    return loss_to_tput

def convert_secs_to_mbps(file_size, secs):
    return (file_size/secs) * 8/1000000

def main():
    assert len(sys.argv) == 6

    tcp_loss_to_tput = extract_data(sys.argv[1], "tcp", REGEX, int(sys.argv[3]))
    quic_loss_to_tput = extract_data(sys.argv[2], "quic", REGEX, int(sys.argv[3]))

    plt.title("%s Mbps Bandwidth with %sms Delay" % (sys.argv[4], sys.argv[5]), size=18)
    plt.xlabel("Packet loss rate (%)", size=20)
    plt.ylabel("Goodput (Mbps)", size=20)
    plt.scatter(tcp_loss_to_tput.keys(), tcp_loss_to_tput.values(), color='red', label="TCP + TLS1.3")
    plt.scatter(quic_loss_to_tput.keys(), quic_loss_to_tput.values(), color='blue', label="QUIC")
    plt.ylim(ymin=0)
    plt.xlim(xmin=-1.0)
    plt.legend(fontsize=20, loc='best')
    graph_title = sys.argv[4] + "mb-" + sys.argv[5] + "ms.png"
    plt.savefig(graph_title)
    print "Check graphs folder for graph: %s" % graph_title

if __name__ == "__main__": main()
