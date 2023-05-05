import numpy as np
import argparse
import sys

class UnrecognizedInstructionException(ValueError):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)

class UnrecognizedRegisterException(ValueError):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)

class InvalidImmediateException(ValueError):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)

class InvalidCommandException(ValueError):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)

class Memory:
    def __init__(self, size):
        self.size = size
        self.bytes = np.zeros(size, dtype = np.uint8)

class CPU:
    def __init__(self):
        self.CFlag = False
        self.ZFlag = False
        self.RegisterFile = np.zeros(8, dtype = np.uint16)

    def add(self, a, b, C):
        S = int(a) + int(b) + int(C)
        s = S%(2**16)
        C = S//(2**16)
        return s, C
    
    def nand(self, a, b):
        return np.bitwise_not(np.bitwise_and(a, b))
    
    def print_state(self, out):
        print("Register File:", file = out)
        print(self.RegisterFile, file = out)
        print("CFlag = " + str(int(self.CFlag)), file = out)
        print("ZFlag = " + str(int(self.ZFlag)) + "\n", file = out)

    def execute(self, line, memory):
        line.replace(',', ' ')
        line_split = line.split(' ')
        opCode = line_split[0]

        if ((opCode == 'ada') or (opCode == 'adc') or (opCode == 'adz') or (opCode == 'awc')):
            rc = int(line_split[1][1])
            ra = int(line_split[2][1])
            rb = int(line_split[3][1])

            if (ra >= 8 or rb >= 8 or rc >= 8 or ra < 0 or rb < 0 or rc < 0):
                raise UnrecognizedRegisterException('Unrecognized register detected')

            if opCode == 'ada' or ((opCode == 'adc') and (self.CFlag)) or ((opCode == 'adz') and (self.ZFlag)):
                s, C = self.add(self.RegisterFile[ra], self.RegisterFile[rb], 0)
                self.RegisterFile[rc] = s
                self.CFlag = bool(C)

            elif opCode == 'awc':
                s, C = self.add(self.RegisterFile[ra] , self.RegisterFile[rb], int(self.CFlag))
                self.RegisterFile[rc] = s
                self.CFlag = bool(C)

            elif opCode == 'aca' or ((opCode == 'acc') and (self.CFlag)) or ((opCode == 'acz') and (self.CFlag)):
                s, C = self.add(self.RegisterFile[ra], ~self.RegisterFile[rb], 0)
                self.RegisterFile[rc] = s
                self.CFlag = bool(C)

            elif opCode == 'acw':
                s, C = self.add(self.RegisterFile[ra] , ~self.RegisterFile[rb], int(self.CFlag))
                self.RegisterFile[rc] = s
                self.CFlag = bool(C)

            self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif opCode == 'adi':
            rb = int(line_split[1][1])
            ra = int(line_split[2][1])
            imm = np.uint16(line_split[3])

            if imm >= 2**6:
                raise InvalidImmediateException('Invalid immediate value, should be 6 bits')

            s, C = self.add(self.RegisterFile[ra], imm, 0)
            self.RegisterFile[rb] = s
            self.CFlag = bool(C)
            self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif (opCode == 'ndu' or opCode == 'ndc' or opCode == 'ndz' or opCode == 'ncu' or opCode == 'ncc' or opCode == 'ncz'):
            rc = int(line_split[1][1])
            ra = int(line_split[2][1])
            rb = int(line_split[3][1])

            if opCode == 'ndu' or (opCode == 'ndc' and self.CFlag) or (opCode == 'ndz' and self.ZFlag):
                self.RegisterFile[rc] = self.nand(self.RegisterFile[ra], self.RegisterFile[rb])

            elif opCode == 'ncu' or (opCode == 'ncc' and self.CFlag) or (opCode == 'ncz' and self.ZFlag):
                self.RegisterFile[rc] = self.nand(self.RegisterFile[ra], ~self.RegisterFile[rb])
            self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif opCode == 'lli':
            ra = int(line_split[1][1])
            imm = np.uint16(line_split[2])

            if imm >= 2**9:
                raise InvalidImmediateException('Invalid immediate value, should be 9 bits')

            self.RegisterFile[ra] = imm
            self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif opCode == 'lw' or opCode == 'sw':
            ra = int(line_split[1][1])
            rb = int(line_split[2][1])
            imm = np.uint16(line_split[3])

            if imm >= 2**9:
                raise InvalidImmediateException('Invalid immediate value, should be 9 bits')
            
            if opCode == 'lw':
                self.RegisterFile[ra] = np.uint16(memory[imm + self.RegisterFile[rb]])

            elif opCode == 'sw':
                memory[imm + self.RegisterFile[rb]] = self.RegisterFile[ra]

            self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif opCode == 'beq' or opCode == 'blt' or opCode == 'ble':
            ra = int(line_split[1][1])
            rb = int(line_split[2][1])
            imm = int(line_split[3])

            if imm >= 2**9:
                raise InvalidImmediateException('Invalid immediate value, should be 9 bits')

            if (opCode == 'beq' and self.RegisterFile[ra] == self.RegisterFile[rb]) or (opCode == 'blt' and self.RegisterFile[ra] < self.RegisterFile[rb]) or (opCode == 'ble' and self.RegisterFile[ra] <= self.RegisterFile[rb]):
                self.RegisterFile[0] = self.RegisterFile[0] + 2*imm

            else:
                self.RegisterFile[0] = self.RegisterFile[0] + 2

        elif opCode == 'jal':
            ra = int(line_split[1][1])
            imm = int(line_split[2])

            if imm >= 2**9:
                raise InvalidImmediateException('Invalid immediate value, should be 9 bits')

            self.RegisterFile[ra] = self.RegisterFile[0] + 2
            self.RegisterFile[0] = self.RegisterFile[0] + 2*imm

        elif opCode == 'jlr':
            ra = int(line_split[1][1])
            rb = int(line_split[2][1])
            self.RegisterFile[ra] = self.RegisterFile[0] + 2
            self.RegisterFile[0] = self.RegisterFile[rb]

        elif opCode == 'jri':
            ra = int(line_split[1][1])
            imm = int(line_split[2])

            if imm >= 2**9:
                raise InvalidImmediateException('Invalid immediate value, should be 9 bits')

            self.RegisterFile[0] = self.RegisterFile[ra] + 2*imm

        else:
            raise UnrecognizedInstructionException('Unrecognized instruction {}'.format(opCode))
            

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--inFile', type = str)
    parser.add_argument('-i', '--interactive', type = bool, default = False)
    parser.add_argument('-o', '--outFile', type = str, default = None)

    args = parser.parse_args()
    inFile = args.inFile
    interactive = args.interactive
    outFile = args.outFile

    if outFile is None:
        out = sys.stdout
    else:
        out = open(outFile, 'w')

    cpu = CPU()
    memory = Memory(2**16)

    with open(inFile) as f:
        lines = f.read().splitlines()
        l = len(lines)
        cpu.RegisterFile[0] = 0
        while cpu.RegisterFile[0] < 2*l:
            line = lines[int(cpu.RegisterFile[0]/2)]
            print(line, file = out)
            if interactive:
                cmd = input('>> ')
                if cmd == 's':
                    cpu.execute(line, memory)
                elif cmd == 'i cpu':
                    print("\nCurrent CPU state:", file = out)
                    cpu.print_state()
                elif cmd == 'i mem':
                    print(memory.bytes, file = out)
                else:
                    raise InvalidCommandException('Invalid command. Valid commands: s, i cpu, i mem')
            else:    
                cpu.execute(line, memory)
        print("\nFinal CPU state:", file = out)
        cpu.print_state(out)

if __name__ == '__main__':
    main()