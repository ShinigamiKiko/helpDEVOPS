import shutil
import os

def check_disk_usage(path='/'):
    total, used, free = shutil.disk_usage(path)

    print(f"Путь: {path}")
    print(f"Всего: {total // (2**30)} Гб")
    print(f"Использовано: {used // (2**30)} Гб")
    print(f"Свободно: {free // (2**30)} Гб")

    if free / total < 0.1:
        print("Внимание: свободного места на диске осталось меньше 10%!")

check_disk_usage()