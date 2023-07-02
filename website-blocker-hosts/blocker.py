import sys
from argparse import ArgumentParser
parser = ArgumentParser()
parser.add_argument('-c', action='store_true')
args = parser.parse_args()

sitesPath = 'blocklist.txt'  # файл с вашими запрещенными зайстами
hostsPath = '/etc/hosts'  # путь к файлу хостс(на винде другой)))
hostsComment = '\n# ' + 'start:site-blocker'  # комментарий для начала блокировки


def main():
    sitesFile = open(sitesPath, 'r')
    sites = sitesFile.read()
    if not sites or sites.isspace():  # make sure the text file is not blank
        sys.exit('blocklist.txt is blank')
    sitesList = sites.splitlines()
    hostsFile = open(hostsPath, 'r')
    hostsContent = hostsFile.read()
    if hostsComment in hostsContent:
        sys.exit('Блокировка активна! используйте для очистки sudo python3 --clear')
    hostsFile.close()  
    hostsFile = open(hostsPath, 'w')
    hostsContent = hostsContent + hostsComment  

    for s in sitesList:
        hostsContent = hostsContent + ('\n127.0.0.1   ' + s)

    hostsFile.write(hostsContent)
    print('Done! Enjoy being distraction free.')


def clear():
    hostsFile = open(hostsPath, 'r')
    hostsContent = hostsFile.read()
    hostsFile.close()  

    clearContent = hostsContent.split(hostsComment)[0]
    hostsFile = open(hostsPath, 'w')
    hostsFile.write(clearContent)

    print('Остановлено...')


if __name__ == "__main__":
    if args.c == True:
        clear()
    else:
        main()
