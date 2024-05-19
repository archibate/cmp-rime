rime_server: rime_server.cpp include Makefile
	g++ -std=c++20 -O3 -DNDEBUG -lrime -luring -lbearssl -lz -Iinclude rime_server.cpp include/co_async/*/*.cpp -o rime_server
