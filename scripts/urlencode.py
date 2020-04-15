import getopt
import sys
import urllib.parse


def usage():
    print('\x1b[1;33;40m' + 'Usage:' + '\x1b[0m' + """
    python urlencode.py -s|--string <string_to_encode>
        With:
            <string_to_encode>: The string to urlencode.
    """)


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

    print(urllib.parse.quote(string_to_encode))


main(sys.argv[1:])
