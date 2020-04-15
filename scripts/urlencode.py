from __future__ import print_function

import getopt
import sys


def usage():
    print('\x1b[1;33;40m' + 'Usage:' + '\x1b[0m' + """
    python urlencode.py -s|--string <string_to_encode>
        With:
            <string_to_encode>: The string to urlencode.
    """)


def encode(arg):
    version = sys.version_info
    if version >= (3, 0) and version < (4, 0):
        import urllib.parse
        return urllib.parse.quote(arg)

    if version >= (2, 0) and version < (3, 0):
        import urllib
        return urllib.quote(arg)
    
    print('\x1b[1;31;40m' + 'ERROR: Unsupported Python version' + '\x1b[0m') 
    sys.exit(3)



def main(argv):
    string_to_encode = ""
    try:
        opts, args = getopt.getopt(argv, "hs:", ["help", "string="])
    except getopt.GetoptError:
        print('\x1b[1;31;40m' +
              'ERROR: Missing or unexpected argument(s)' + '\x1b[0m')
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif opt in ("-s", "--string"):
            string_to_encode = arg

    # Checks that no additional args are provided:
    other_args = "".join(args)
    if len(other_args) > 0:
        print('\x1b[1;31;40m' + 'ERROR: Unexpected argument(s)' + '\x1b[0m')
        usage()
        sys.exit(2)

    # Checks that a bucket name is provided:
    if string_to_encode == "":
        print('\x1b[1;31;40m' + 'ERROR: Missing string' + '\x1b[0m')
        usage()
        sys.exit(2)

    print(encode(string_to_encode))


if __name__ == "__main__":
    main(sys.argv[1:])
