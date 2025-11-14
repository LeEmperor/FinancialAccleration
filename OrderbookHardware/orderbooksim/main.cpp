#include <iostream>
#include <array>
#include <map>
#include <stack>
// #include <algorithm>
#include <vector>
#include <fstream>
#include <string>
#include <sstream>

#define nL "\n"
#define BRAM_SIZE             1024
#define SLOTS_PER_LEVEL       10
#define NUMBER_OF_LEVELS      100

void Disp(int thingy, std::string in_string) {
  std::cout << in_string << thingy << nL;
}

typedef enum {
  NO_ERR,
  INVALID_INSTR,

  BRUH
} InstrumentErr_e;

typedef enum {
  ADD,
  MODIFY,
  DELETE
} InstrType_e;

typedef struct {
  InstrType_e InstrType;
  std::string Ticker;
  uint64_t Price;
  uint16_t Quantity;
  uint64_t Epoch;
  uint64_t OrderID;
} ExchangeInstruction_t;

typedef struct SlotItem_t {
  uint8_t quantity = 0;
  uint64_t vendor_id = -1; // le meme de orderid
  uint8_t seq_prio = 0;
  uint64_t epoch = -1;
  int next_idx = -1;
  int prev_idx = -1;
} SlotItem_t;

class Level {
  public:
    // members
    std::stack<int> free_list;
    int tail = 0; // newest, just got added
    int head = 0; // oldest, we want this

    // methods
    Level(void) {
      // default constructor 
      // std::cout << "default level constructor called" << nL;
      for(int i = SLOTS_PER_LEVEL - 1; i >= 0; i--) {
        free_list.push(i);
        // std::cout << "pushing: " << i << " on the level constructor" << nL;
      }
    }

    int AlloqIdx(void) {
      int to_return = head;
      free_list.pop();

      // if(free_head == SLOTS_PER_LEVEL) {
      //   std::cout << "free list empty, need to drop or rewrite old data";
      // }

      head = free_list.top();
      return to_return;
    }

    InstrumentErr_e FreeIdx(int idx_to_free) {
      free_list.push(idx_to_free);
      head = idx_to_free; // free_list.top()?
      Disp(head, "freed: ");
      return NO_ERR;
    }

    int GetFreeListHead(void) {
      return head;
    }

    int GetFreeListTail(void) {
      return tail;
    }

    void SetFreeListTail(int neu) {
      tail = neu;
    }

    void DispFreeListHead(void) {
      std::cout << "head of freelist: " << head << nL;
    }

    void DispFreeList(void) {
      std::cout << "displaying free list items" << nL;
      std::stack<int> temp = free_list;

      while(!temp.empty()) {
        std::cout << temp.top() << nL;
        temp.pop();
      }
    }

    ~Level() {
      // default destructor
      // std::cout << "default level destructor called" << nL;
    }
};

class SingleInstrumentCore {
  public:
    // members
    std::vector<Level> levels;
    std::map<int, int> level_map; // mem[0] c'est pas la prix = 0, c'est la prix plus petit avec la range de consideration
    std::array<SlotItem_t, NUMBER_OF_LEVELS * SLOTS_PER_LEVEL> mem;
    std::vector<ExchangeInstruction_t> exchange_instructions;

    // fast locator table
    std::map<int, int> locator_table;

    void DispMem(void) {
      for(int i = 0; i < mem.size(); i++) {
        // std::cout << "looking at index i: " << i << nL;
        SlotItem_t a = mem[i];
        if(a.quantity != 0) {
          std::cout << "-------------------------------" << nL;
          Disp(i, "");
          Disp(a.prev_idx, "prev idx: ");
          Disp(a.next_idx, "next idx: ");
          Disp(a.epoch, "epoch: ");
          Disp(a.quantity, "qty: ");
          Disp(a.vendor_id, "id: ");
        } else continue;
      }
    }

    void DispLocatorTable(void) {
      for(const auto& [key, value] : locator_table) {
        std::cout << "key: " << key << " value: " << value << nL;
      }
    }

    int next_map_idx = 0;
    // methods

    void DispLevelMap(void) {
      for(auto a = level_map.cbegin(); a != level_map.cend(); a++) {
        std::cout << "map index: " << a->first << "      attached item: " << a->second << nL;
      }
    }

    // get the level multiplicative index from the map
    // for example,
    // USD25 -> index0
    int GetLevelMapIdx(int price) {
      if (level_map.count(price)) {
        return level_map[price];
      } else {
        level_map[price] = next_map_idx++;
        return level_map[price];
      }
      return 0;
    }

    InstrumentErr_e ParseOrder(std::string line) {
      ExchangeInstruction_t instr;

      std::istringstream ss(line);
      std::string cmd, ticker;
      int price, qty, epoch, orderid = 0;

      ss >> cmd;
      if (cmd == "ADD") {
        instr.InstrType = ADD;
      } else if (cmd == "MODIFY") {
        instr.InstrType = MODIFY;
      } else if (cmd == "DELETE") {
        instr.InstrType = DELETE;
      } else {
        std::cout << "found invalid instr" << nL;
        return INVALID_INSTR;
      }
      return NO_ERR;
    }

    InstrumentErr_e Command_MODIFY(ExchangeInstruction_t instr) {
      int fast_index = locator_table[instr.OrderID]; // besoin d'un empty check
      Disp(fast_index, "fast index lookup on modify ");
      SlotItem_t fast_item = mem[fast_index];

      std::cout << "found item with order_id: " << instr.OrderID << nL;
      Disp(fast_item.vendor_id, "found vendor id: ");
      Disp(fast_item.quantity, "current qty: ");

      mem[fast_index].quantity = instr.Quantity;
      mem[fast_index].epoch = instr.Epoch;

      return NO_ERR;
    }

    InstrumentErr_e Command_DELETE(ExchangeInstruction_t instr) {
      int fast_index = locator_table[instr.OrderID];
      Disp(fast_index, "fast index lookup on delete ");
      int level = level_map[instr.Price];
      Disp(level, "utilized level map item: ");

      SlotItem_t* item_to_remove = &mem[fast_index]; // pourquoi  // utiliser les adresses integers
      item_to_remove->epoch = -1;

      SlotItem_t* prev_item = &mem[level * SLOTS_PER_LEVEL + (item_to_remove->prev_idx)];

      int current_addr =  fast_index;

      Disp(current_addr,  "mem addr of removing item ");

      int prev_addr = level * SLOTS_PER_LEVEL + mem[fast_index].prev_idx;
      Disp(prev_addr,     "mem addr of prev item ");

      int next_addr = level * SLOTS_PER_LEVEL + mem[fast_index].next_idx;
      Disp(next_addr,     "mem addr of next item ");

      // voir at head
      if (item_to_remove->next_idx == -1) {
        std::cout << "trying to remove head" << nL;
        prev_item->next_idx = -1;
      } else {
        Disp(instr.Price, "basing level on price: ");
        levels[level].FreeIdx(fast_index);
        mem[next_addr].prev_idx = item_to_remove->prev_idx;
        std::cout << "item_to_remove prev_idx: " << item_to_remove->prev_idx << nL;
        mem[level * SLOTS_PER_LEVEL + (item_to_remove->prev_idx)].next_idx = item_to_remove->next_idx;
        // Disp(item_to_remove->next_idx, "removing item next: ");
        // Disp(item_to_remove->prev_idx, "removing item prev: ");

        // calculer les adresses
        // int prev_item_addr = level * SLOTS_PER_LEVEL + item_to_remove
      }

      // 1 -> 2 -> 3 => 1 -> 2
      // 1 -> 2 -> 3 => 1 -> 3

      return NO_ERR;
    }

    InstrumentErr_e Command_ADD(ExchangeInstruction_t instr) {
      // à cet point, on sait qu'il y a un ADD instr

      // data extraction
      SlotItem_t new_slot_item;
      new_slot_item.quantity = instr.Quantity;
      new_slot_item.epoch = instr.Epoch;
      new_slot_item.vendor_id = instr.OrderID;
      new_slot_item.next_idx = -1;
      new_slot_item.prev_idx = -1;
      new_slot_item.seq_prio = -1;

      // calculer l'adresse nouvelle
      // c'est un vérifier redundante -> GetLevelMapIdx on un vérifier
      int level = -1;
      if (level_map.count(instr.Price)) { // stack locality on instr.price?
        // presente
        level = level_map[instr.Price];
      } else {
        // pas présente
        level = GetLevelMapIdx(instr.Price);
      } 

      int new_idx = levels[level].AlloqIdx(); // offset pour le slot
      int new_item_addr = level * SLOTS_PER_LEVEL + new_idx;

      int old_tail = levels[level].GetFreeListTail();
      int prev_item_addr = level * SLOTS_PER_LEVEL + old_tail;

      mem[new_item_addr] = new_slot_item;
      // écrire la resulte
      if (new_idx == old_tail) { // cette case est fucked
        mem[new_item_addr].prev_idx = 0;
        mem[new_item_addr].next_idx = 0;
      } else {
        mem[new_item_addr].prev_idx = old_tail;
        mem[prev_item_addr].next_idx = new_idx;
        levels[level].SetFreeListTail(new_idx);
      }

      locator_table[new_slot_item.vendor_id] = new_item_addr;

      return NO_ERR;
    }

    InstrumentErr_e AddOrder(std::string line) {
      ExchangeInstruction_t instr;
      std::istringstream ss(line);
      std::string cmd;

      ss >> cmd;
      if (cmd == "ADD") {
        instr.InstrType = ADD;
        ss >> instr.Ticker >> instr.Price >> instr.Quantity >> instr.Epoch >> instr.OrderID;
        Command_ADD(instr);
      } else if (cmd == "MODIFY") {
        instr.InstrType = MODIFY;
        // std::cout << "modify instructoin found" << nL;
        ss >> instr.Ticker >> instr.Price >> instr.Quantity >> instr.Epoch >> instr.OrderID;
        Command_MODIFY(instr);
      } else if (cmd == "DELETE") {
        instr.InstrType = DELETE;
        ss >> instr.Ticker >> instr.Price >> instr.Quantity >> instr.Epoch >> instr.OrderID;
        Command_DELETE(instr);
      } else {
        std::cout << "found invalid instr" << nL;
        return INVALID_INSTR;
      }

      return NO_ERR;
    }

    void DispLevelDataTarget(int i) {
      levels[i].DispFreeList();
    }

    void SetLevelMap(int i) {
      level_map[i] = next_map_idx;
      next_map_idx += 1;
    }

    int GetNumberLevels(void) const {
      return levels.size();
    }

    SingleInstrumentCore() {
      for(int i = 0; i < 10; i++) {
        levels.emplace_back();
      }
    }

    SingleInstrumentCore(std::vector<std::string> input) {
      // line constructor

      for(auto line : input) {
        std::cout << "constructor parsing: " << line << nL;
      }
    }

    ~SingleInstrumentCore() {
      // std::cout << "default destructor called" << nL;
    }
};

int main(void) {
  std::cout << "program start!" << nL;

  std::ifstream input_stream("input.txt");
  std::ofstream output_stream("output.txt");
  std::ofstream log_stream("latest_log.txt");

  SingleInstrumentCore Book;

  bool breaking = false;
  std::string line;
  std::vector<std::string> lines;
  while(getline(input_stream, line)) {
    if(!line.empty() && line.back() == '\r') line.pop_back();
    if(line.empty()) continue;
    if(line[0] == '#') continue;
    lines.push_back(line);
  }

  // Book.SetLevelMap(15);
  // Book.SetLevelMap(20);

  const int size = lines.size();
  for(int i = 0; i < size; i++) {
    std::cout << "---------------------------------" << nL;
    std::cout << "parsing order: " << lines[i] << nL;
    Book.AddOrder(lines[i]);
  }

  std::cout << "-----------------------------------" << nL;

  Book.DispMem();
  // Book.DispLocatorTable();
}


