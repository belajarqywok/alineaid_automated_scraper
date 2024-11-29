import argparse

from urls import save_urls
from contents import save_contents


def main() -> None:
    parser = argparse.ArgumentParser(
      description = "Alineaid Automated Scraper")

    parser.add_argument(
      '-i', '--iterations', type = int,
      required = True, help = 'iterations')

    parser.add_argument(
      '-w', '--workers', type = int,
      required = True,help = 'workers')

    args = parser.parse_args()

    save_urls(args.iterations)
    save_contents(args.workers)

if __name__ == "__main__": main()