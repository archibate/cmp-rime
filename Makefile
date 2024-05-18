httprime: httprime.c Makefile
	gcc -O3 -DNDEBUG -lrime httprime.c -o httprime

luarime.so: luarime.c Makefile
	gcc -I/usr/include/luajit-2.1/ -O3 -DNDEBUG -shared -lrime -llua luarime.c -o luarime.so
