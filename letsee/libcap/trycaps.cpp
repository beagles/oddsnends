#include <cap-ng.h>

#include <iostream>
#include <fstream>
#include <string>
#include <exception>
using namespace std;

int main(int, char**)
{
    capng_clear(CAPNG_SELECT_BOTH);

    capng_updatev(CAPNG_ADD, CAPNG_BOUNDING_SET, CAP_NET_ADMIN, CAP_NET_RAW,
        CAP_DAC_READ_SEARCH, -1);
    capng_apply(CAPNG_SELECT_BOTH);

    try
    {
        ifstream i;
        i.exceptions(ifstream::failbit | ifstream::badbit);
        i.open("foo.dat");
        char buffer[512];

        i.getline(buffer, sizeof(buffer)/sizeof(buffer[0]));
        cout << buffer << endl;
    }
    catch(const exception& ex)
    {
        cerr << "Unable to open/read file" << endl;
    }

    return 0;
}
