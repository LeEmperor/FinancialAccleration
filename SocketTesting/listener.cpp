#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netpacket/packet.h>
#include <net/ethernet.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <iostream>

#define CUSTOM_ETHERTYPE 0xBB85

using namespace std;

int main() {
  uint8_t* SocketName = "enp0s8";

  uint8_t FrameBuffer[2048];
  struct ifreq ifr;
  int sockfd;
  int boundsocket;
  int boundsocket2;

  // setup listening socket
  sockfd = socket(AF_PACKET, SOCK_RAW, htons(CUSTOM_ETHERTYPE));
  if (sockfd == -1) {
    perror("socket creation failure");
    exit(EXIT_FAILURE);
  }

  // bind socket
  memset(&ifr, 0, sizeof(struct ifreq));
  strncpy(ifr.ifr_name, "enp0s8", IFNAMSIZ - 1);
  boundsocket = ioctl(sockfd, SIOCGIFINDEX, &ifr);
  if (boundsocket == -1) {
    perror("socket interface finding failed");
    close(sockfd);
    exit(EXIT_FAILURE);
  }

  struct sockaddr_ll saddr = {0};
  saddr.sll_family = AF_PACKET;
  saddr.sll_protocol = htons(CUSTOM_ETHERTYPE);
  saddr.sll_ifindex = ifr.ifr_ifindex;

  boundsocket2 = bind(sockfd, (struct sockaddr*)&saddr, sizeof(saddr));
  if (boundsocket2 == -1) {
    perror("binding fail");
    exit(EXIT_FAILURE);
  }

  printf("Listening on interface %s for ethertype 0x%X...\n", SocketName, CUSTOM_ETHERTYPE);







  close(sockfd);
  return 0;
}



