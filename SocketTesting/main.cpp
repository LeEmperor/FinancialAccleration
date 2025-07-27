// C headers
#include <cstdlib>
#include <linux/if_ether.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/ether.h>
#include <netpacket/packet.h>
#include <sys/socket.h>
#include <net/if.h>
#include <sys/ioctl.h>

// C++ headers
#include <iostream>



using namespace::std;

int main() {
    // cout << "testing!" << endl;
    // cout << "running main!" << endl;
    printf("making socket\n");

    int socket_fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (socket_fd < 0) {
        perror("socket fd failure");
        exit(EXIT_SUCCESS);
    }
    printf("raw socket created on fd: %i\n", socket_fd);

    // ifreq for interface index
    struct ifreq InterfaceRequest;
    strncpy(InterfaceRequest.ifr_name, "eth0", IFNAMSIZ - 1);

    // interface index of eth0
    int socket_ioctl = ioctl(socket_fd, SIOCGIFINDEX, );





}

