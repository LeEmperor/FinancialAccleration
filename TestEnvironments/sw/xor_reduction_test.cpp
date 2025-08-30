#include <iostream>
#include <array>

#define nL "\n"

template <std::size_t N>
const void printArr(const std::array<int, N>& arr) { // try spans plus-tard
  std::cout << "arr: ";
  for (auto i : arr) {
    std::cout << i << " "; 
  }
  std::cout << nL;
}

// const void inlineArr(const std::array<int, N)& arr) {
//   for (auto i : arr) {
//     std::cout << i << " ";
//   }
// }

const void printconsole_noflush(const std::string input_string) {
  std::cout << input_string << nL;
}

int main(void) {
  std::cout << "program started" << nL;

  std::array<int, 20> inputs;
  std::array<int, 10> outputs;

  std::fill(inputs.begin(), inputs.begin() + 5, 1);
  std::fill(inputs.begin()+5, inputs.end(), 0);
  std::fill(outputs.begin(), outputs.end(), 0);

  // printconsole_noflush("inputs: before");
  // printArr(inputs);
  //
  // printconsole_noflush("outputs: before");
  // printArr(outputs);

  const int width = 20;
  for(int i = 0; i < (width / 2); i+=2) {
    std::cout << "i:" << i << " ";
    std::cout << "arg1: "  << outputs[i] << " arg2: " << outputs[i + 1];
    printconsole_noflush(" ");
    outputs[i] = inputs[i] & inputs[i + 1];
  }

  printconsole_noflush(" ");
  printconsole_noflush("outputs: after");
  printArr(outputs);

  return 0;
}
