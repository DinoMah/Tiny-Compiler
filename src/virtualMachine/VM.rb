require './src/virtualMachine/Instruction.rb'
require 'fox16'

include Fox

class VirtualMachine
    public def init
        @assemblies.each do
            self.readInstruction
        end
    end

    def initialize(symbolTable, ideInstance)
        @queue = Array.new
        @instruction = %w{ adi sub mul div res lda stn gtn ltn gte lte equ dif ldc lod rdi wri lds fjp ujp lab Error }
        @validTypes = %w{ integer float bool }
        @assemblies = Array.new
        @symbolTable = symbolTable
        @currentInstruction = 0
        @ideInstance = ideInstance
        self.createInstructionArray
    end

    private

    attr_accessor :queue
    attr_accessor :instruction
    attr_accessor :assemblies
    attr_accessor :symbolTable
    attr_accessor :currentInstruction
    attr_accessor :validTypes
    attr_accessor :ideInstance
    
    def createInstructionArray
        if !(File.zero? 'Datos/assemblies.txt')
            pos = 0
            instruction = Array.new
            File.foreach 'Datos/assemblies.txt' do |line|
                instruction = line.split ' '
                if instruction.length <= 2
                    @assemblies[pos] = Instruction.new instruction[0], instruction[1]
                else
                    string = ''
                    for i in 1...instruction.length
                        string += instruction[i] + ' '
                    end
                    @assemblies[pos] = Instruction.new instruction[0], string
                end
                pos += 1
            end
        else
            puts 'There isn\'t any code to execute, aborting...'
        end
    end

    def getCommand currentInstruction
        return @assemblies[currentInstruction].command
    end

    def getValue currentInstruction
        return @assemblies[currentInstruction].value
    end

    def readInstruction
        puts @assemblies[@currentInstruction].command + ' ' + @assemblies[@currentInstruction].value.to_s
        error = nil
        case self.getCommand @currentInstruction
        when @instruction[0]
            self.adi
        when @instruction[1]
            self.sub
        when @instruction[2]
            self.mul
        when @instruction[3]
            error = self.div
        when @instruction[4]
            error = self.res
        when @instruction[5]
            self.lda
        when @instruction[6]
            self.stn
        when @instruction[7]
            self.gtn
        when @instruction[8]
            self.ltn
        when @instruction[9]
            self.gte
        when @instruction[10]
            self.lte
        when @instruction[11]
            self.equ
        when @instruction[12]
            self.dif
        when @instruction[13]
            self.ldc
        when @instruction[14]
            self.lod
        when @instruction[15]
            self.rdi
        when @instruction[16]
            self.wri
        when @instruction[17]
            self.lds
        when @instruction[18]
            self.fjp
        when @instruction[19]
            self.ujp
        when @instruction[20]
            self.lab
        when @instruction[21]
            error = self.Error
        end
        @currentInstruction += 1
        
        if error != nil
            return error
        else
            return nil
        end
    end

    def adi
        pair = self.getFromQueue
        result = self.getNum(pair[0]) + self.getNum(pair[1])
        self.saveOnQueue result
    end

    def sub
        pair = self.getFromQueue
        result = self.getNum(pair[0]) - self.getNum(pair[1])
        self.saveOnQueue result
    end

    def mul
        pair = self.getFromQueue
        result = self.getNum(pair[0]) * self.getNum(pair[1])
        self.saveOnQueue result
    end

    def div
        pair = self.getFromQueue
        if pair[1] == 0
            return 'Error: Can\'t process division by 0.'
        end
        result = self.getNum(pair[0]) / self.getNum(pair[1])
        self.saveOnQueue result
    end

    def res
        pair = self.getFromQueue
        if pair[1] == 0
            return 'Error: Can\'t process division by 0.'
        end
        result = self.getNum(pair[0]) % self.getNum(pair[1])
        self.saveOnQueue result
    end

    def lda
        self.saveValueOnQueue
    end

    def stn
        pair = self.getFromQueue
        self.symbolTable[pair[0]].valor = self.getNum pair[1]
        @queue.pop
    end

    def gtn
        pair = self.getFromQueue
        if self.getNum(pair[0]) > self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def ltn
        pair = self.getFromQueue
        if self.getNum(pair[0]) < self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def gte
        pair = self.getFromQueue
        if self.getNum(pair[0]) >= self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def lte
        pair = self.getFromQueue
        if self.getNum(pair[0]) <= self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def equ
        pair = self.getFromQueue
        if self.getNum(pair[0]) == self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def dif
        pair = self.getFromQueue
        if self.getNum(pair[0]) != self.getNum(pair[1])
            self.saveOnQueue true
        else
            self.saveOnQueue false
        end 
    end

    def ldc
        self.saveValueOnQueue
    end

    def lod
        var = @assemblies[@currentInstruction].value
        self.saveOnQueue self.symbolTable[var].valor
    end

    def rdi
        address = @queue.pop
        input = FXInputDialog.getString('Data', @ideInstance, 'Data', 'Give me a number: ')
        inputType = self.determineType input
        case inputType
        when @validTypes[0], @validTypes[1]
            if @symbolTable[address].tipo == inputType
                @symbolTable[address].valor = self.getNum input
            else
                self.showMessage 'Warning!', 'Types of variable and input are incompatible'
            end
        when @validTypes[2]
            if @symbolTable[address].tipo == inputType
                @symbolTable[address].valor = input
            else
                self.showMessage 'Warning!', 'Types of variable and input are incompatible'
            end
        else
            self.showMessage 'Warning!', 'Unknown var type, omitting...'
        end
    end

    def showMessage(messageType, message)
        FXMessageBox.warning @ideInstance, MBOX_OK, messageType, message
    end
    
    def wri
        # Enviar informacion al texto del ide
        pair = self.getFromQueue
        if !(pair[0].instance_of? String)
            self.saveOnQueue pair[0]
            popMessage = FXMessageBox.new(
                @ideInstance, 
                "Mensaje:", 
                pair[1].to_s,
                nil, 
                MBOX_OK|DECOR_TITLE|DECOR_BORDER
            )
            popMessage.execute
        else
            popMessage = FXMessageBox.new(
                @ideInstance, 
                "Mensaje:", 
                pair[0].to_s + pair[1].to_s,
                nil, 
                MBOX_OK|DECOR_TITLE|DECOR_BORDER
            )
		    popMessage.execute
        end
    end
    
    def lds
        self.saveValueOnQueue
    end
    
    def fjp
        comparisonResult = @queue.pop
        if comparisonResult.is_a? String
            comparisonResult = !comparisonResult
        end
        if !comparisonResult
            labelPosition = self.searchLabel @assemblies[@currentInstruction].value
            self.jumpTo labelPosition
        end
    end
    
    def ujp
        labelPosition = self.searchLabel @assemblies[@currentInstruction].value
        self.jumpTo labelPosition
    end

    def lab
        # Este metodo no hace nada jajaja
    end
    
    def Error
        return 'Error: Unknown command.'
    end

    def getFromQueue
        return @queue.pop(2)
    end

    def saveOnQueue(value)
        @queue.push value
    end

    def saveValueOnQueue
        self.saveOnQueue @assemblies[@currentInstruction].value
    end

    def getNum(string)
        if string.instance_of? String
            if (string =~ /[[:digit:]]/) == 0
                if string.include? '.'
                    return string.to_f
                else
                    return string.to_i
                end
            else
                return 0
            end
        else
            return string
        end
    end

    def determineType(input)
        input = input.strip unless input == nil
        if input == nil
            return 'nil'
        elsif (input =~ /[[:digit:]]/) == 0
            if input.include? '.'
                return 'float'
            else
                return 'integer'
            end
        elsif input == 'true' || input == 'false'
            return 'bool'
        else
            return 'unknown'
        end
    end

    def searchLabel(labelNumber)
        labelIndex = @assemblies.index { |e| e.command == 'lab' && e.value == labelNumber }
        return labelIndex
    end

    def jumpTo(labelPosition)
        @currentInstruction = labelPosition
    end
end