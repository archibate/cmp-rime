rime_server: rime_server.cpp single_co_async.hpp Makefile
	g++ -std=c++20 -O3 -DNDEBUG -lrime -luring -lbearssl -lz -I. rime_server.cpp -DCO_ASYNC_IMPLEMENTATION -o rime_server
