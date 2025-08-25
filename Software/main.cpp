#include <iostream>
#include <array>

#define nL "\n"

const void printArr(const std::array<int, 10> arr) {
  for (auto i : arr) {
    std::cout << "item: " << i << nL;
  }
}

int main(void) {
  std::cout << "started!" << nL;


  std::array<int, 10> bids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  std::array<int, 10> bids_r = bids;

  // case 1 no space

  const int target_index = 4; // value 5 dans l'array
  //
  std::cout << "before: " << nL;
  printArr(bids);

  for(int i = target_index; i < 10; i++) {
    bids[i] = bids_r[i - 1];
  }

  bids[target_index] = 100;

  std::cout << "after: " << nL;
  printArr(bids);

  // case 2 space



  return 0;
}

