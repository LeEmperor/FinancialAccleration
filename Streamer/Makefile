CXX = clang++
CXXFLAGS = -std=c++17 -Wall

INCLUDES = 
LIBS = -lcpprest -lcrypto  

main: main.cpp 
	$(CXX) $(CXXFLAGS) $(INCLUDES) main.cpp -o exec $(LIBS)

clean:
	rm -f main
