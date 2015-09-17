trycaps.cpp
Demonstrating how the capabilities library can restrict access to
disallow root from reading a file.

Compile:
c++ -o trycaps trycaps.cpp -lcap-ng

With foo.dat in the current directory and permissions equivalent to UID,
run:

./trycaps

Should print the contents of foo.dat

sudo ./trycaps

Should print a message that an exception has occurred.

sudo chown root ; sudo chmod 0600 foo.dat

sudo ./trycaps

Should print the contents of foo.dat
