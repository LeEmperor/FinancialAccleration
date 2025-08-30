#include <cstdlib>
#include <iostream>
#include <string>
#include <stdint.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <arpa/inet.h>
#include <array>
#include <algorithm>
using namespace std;

class Ethernet {
    public:
        string instance_name;

        // default constructor
        Ethernet() {
            cout << "new ethernet made\n" << endl;
        }
};

#pragma pack(push,1)
struct TradePayload {
    uint64_t timestamp;
    uint32_t price;
    uint16_t size;
};
#pragma pack(pop)

struct EthernetFrame {
    // 8
    uint8_t preamble[8];

    // 14
    struct header {
        uint8_t destination[6]; // destination mac address (this is 6 bytes = 6 * 8bits)
        uint8_t source[6]; // source mac address
        uint16_t ethernetType; // 2 bytes = 16 bits 
    };

    // 46 <= x < 1500
    struct payload {

    };

    // padding

    // frame check sequence (fcs)
    uint8_t frameCheckSequence[4]; 
};

struct EthernetHeader_t {
    uint8_t destination[6]; // destination mac address (this is 6 bytes = 6 * 8bits)
    uint8_t source[6]; // source mac address
    uint16_t ethernetType; // 2 bytes = 16 bits 
};

#pragma pack(push, 1)
struct TradePayload_t {
    uint8_t ticker[8];
    uint8_t volume;
    uint8_t price;
};
#pragma pack(pop)

int main(void) {
    // variable setup : slice the frame into chunks and write to the chunks easier
    uint8_t ETHERNET_FRAME[1514];
    EthernetHeader_t* header = (EthernetHeader_t*)ETHERNET_FRAME; 
    TradePayload_t* payload = (TradePayload_t*)(ETHERNET_FRAME + sizeof(header));

    // MACs
    uint8_t pc_mac[6]   = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    uint8_t fpga_mac[6] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    memcpy(header->destination, fpga_mac, 6);
    memcpy(header->source, pc_mac, 6);

    // custom eth type = 0x8885
    header->ethernetType = htons(0x8885);

    // payload (after header)
    // uint8_t testTicker[8] = "AAPL";
    // std::array<uint8_t, 8> TestTicker{"AAPL"};
    strncpy(reinterpret_cast<char*>(payload->ticker), 
            "AAPL", 
            4);

    payload->volume = 150;
    payload->price = 172;


    // figure out frame length
    size_t payloadLength = sizeof(payload);
    size_t frameLength = sizeof(header) + payloadLength;
    if (frameLength < 60) frameLength = 60; // pad, NIC will cover the FCS




    // send via AF_PACKET

    // open raw socket
    int sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sock < 0) { perror("socket init failed"); return -1;}

    // get interface index (which eth module instance ex: "eth0")
    struct ifreq ifr{};
    std::strncpy(ifr.ifr_name, "eth0", IFNAMSIZ - 1);
    if (ioctl(sock, SIOCGIFINDEX, &ifr) < 0) {
        perror("ioctl ethernet module reservation failed");
        close(sock);
        return -1;
    }
    int ifindex = ifr.ifr_ifindex;
    if (ioctl(sock, SIOCGIFHWADDR, &ifr) < 0) {
        perror("ioctl hwaddr - destination mac construction failed");;;;
        close(sock);
        return -1;
    }
    std::memcpy(pc_mac, ifr.ifr_hwaddr.sa_data, 6);

    struct sockaddr_ll addr{};


    return 0;
}

