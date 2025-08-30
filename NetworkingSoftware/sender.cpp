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

  // int socket_fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
  int socket_fd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW);
  if (socket_fd == -1) {
      perror("socket fd failure");
      exit(EXIT_SUCCESS);
  }
  printf("raw socket created on fd: %i\n", socket_fd);

  // ifreq for interface index
  const char* InterfaceName = "enp0s8";
  struct ifreq EthernetHandle_InterfaceRequest;
  strncpy(EthernetHandle_InterfaceRequest.ifr_name, InterfaceName, IFNAMSIZ - 1);

  // interface index of eth0 (ce qu'est enp0s8 de passthrough Virtualbox)
  int OriginSocket = ioctl(socket_fd, SIOCGIFINDEX, &EthernetHandle_InterfaceRequest);

  //  mac address
  uint8_t MacAddress[6] = {0x08, 0x00, 0x27, 0xBC, 0x3E, 0x78};
  memcpy(MacAddress, EthernetHandle_InterfaceRequest.ifr_hwaddr.sa_data, 6);

  // destination address
  struct sockaddr_ll TargetSocket = {
    .sll_family = AF_PACKET,
    .sll_protocol = htons(ETH_P_ALL),
    .sll_ifindex = EthernetHandle_InterfaceRequest.ifr_ifindex, 
    .sll_halen = ETH_ALEN,
  };

  // send back to itself
  memcpy(TargetSocket.sll_addr, MacAddress, 6);

  // build frame
  // #define ETH_FRAME_LEN 10
  uint8_t EthernetFrame[ETH_FRAME_LEN];
  struct ether_header* EthernetFrameHeader = (struct ether_header *)EthernetFrame;
  memcpy(EthernetFrameHeader->ether_shost, MacAddress, 6);
  memcpy(EthernetFrameHeader->ether_dhost, MacAddress, 6);
  EthernetFrameHeader->ether_type = htons(0x88B5); // custom frame type

  const uint8_t payload[] = "Hello, World!";
  const size_t payload_len = sizeof(payload); 

  memcpy(EthernetFrame + sizeof(struct ether_header), payload, payload_len);

  cout << "preparing payload: " << payload << "\n";

  //  sendto
  //  int sockfd
  //  const void* buf
  //  size_t len
  //  int flags
  //  const struct sockaddr* dest_addr
  //  socklen_t addrlen

  ssize_t sent = sendto(
    OriginSocket,
    EthernetFrame,
    sizeof(struct ether_header) + payload_len,
    0,
    (struct sockaddr*)&TargetSocket, 
    sizeof(struct sockaddr_ll)
  );

  if (sent == -1) {
    perror("sendto failed");
  }

  // cout << "Sent %zd bytes\n", sent);
  printf("Sent %zd bytes\n", sent);
  close(OriginSocket);
}



