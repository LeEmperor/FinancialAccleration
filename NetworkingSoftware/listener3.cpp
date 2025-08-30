#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <net/ethernet.h>
#include <netpacket/packet.h>
#include <net/if.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>

#define CUSTOM_ETHERTYPE 0xBB85
#define MAX_PACKET_SIZE 2048

// STATUS: listener pas complet'e
// shared mode??

int main(int argc, char *argv[]) {
    const char *iface = (argc > 1) ? argv[1] : "enp0s8";
    int sockfd;
    struct ifreq ifr;

    // Create a raw socket listening for custom EtherType
    if ((sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

  // non-blocking socket
  int flags = fcntl(sockfd, F_GETFL, 0);
  if (flags < 0 || fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) < 0) {
    perror("fcntly nonblock socket setting failed");
    close(sockfd);
    exit(EXIT_FAILURE);
  }

    // Bind socket to specified interface
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, iface, IFNAMSIZ - 1);
    if (ioctl(sockfd, SIOCGIFINDEX, &ifr) < 0) {
        perror("SIOCGIFINDEX call failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

  printf("binding to ifindex: %d (%s)\n", ifr.ifr_ifindex, iface);

    struct sockaddr_ll saddr = {0};
    saddr.sll_family   = AF_PACKET;
    saddr.sll_protocol = htons(CUSTOM_ETHERTYPE);
    saddr.sll_ifindex  = ifr.ifr_ifindex;

    if (bind(sockfd, (struct sockaddr *)&saddr, sizeof(saddr)) == -1) {
        perror("bindind error");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    printf("Listening on interface %s for EtherType 0x%X...\n", iface, CUSTOM_ETHERTYPE);

    // Main receive loop
    uint8_t buffer[MAX_PACKET_SIZE];
    while (1) {
      ssize_t len = recvfrom(sockfd, buffer, sizeof(buffer), 0, NULL, NULL);

      if (len > 0) {
        printf("\nReceived %zd bytes:\n", len);
        printf("Payload:\n");

        for (int i = 14; i < len; i++) {
            printf("%02X ", buffer[i]);
            if ((i - 14 + 1) % 16 == 0) printf("\n");
        }

      }

      usleep(1000);
    }

    close(sockfd);
    return 0;
}
