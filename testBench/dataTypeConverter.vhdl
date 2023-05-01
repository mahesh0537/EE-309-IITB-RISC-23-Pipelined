library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;

package dataTypeConverter is
    function std_logic_to_string(std_logic_val : std_logic) return String;
    file output : text open write_mode is "console.log";   
    procedure writer16(a : in std_logic_vector(15 downto 0));
    function to_string(x: string) return string;
    function to_std_logic_vector(x: bit_vector) return std_logic_vector;
    function to_bit_vector(x: std_logic_vector) return bit_vector;
    function bit_to_std_logic(bit_val : bit) return std_logic;
    function std_logic_to_bit(std_logic_val : std_logic) return bit;




end dataTypeConverter; 

package body dataTypeConverter is
    function zeroFlagFinder(a : in std_logic_vector(15 downto 0)) return std_logic is
        begin
            if a = x"0000" then
                return '1';
            else
                return '0';
            end if;
    end function zeroFlagFinder;
    function carryFlagFinder(operandAmsp :in std_logic; operandBmsp : in std_logic; resultmsp :in std_logic) return std_logic is
        begin
            if resultmsp = '1' then
                return '1';
            else
                return '0';
            end if;
    end function carryFlagFinder;
    function std_logic_to_string(std_logic_val : std_logic) return String is
        begin
            if std_logic_val = '0' then
            return "0";
            else
            return "1";
            end if;
    end function;
    procedure writer16(a : in std_logic_vector(15 downto 0)) is
        begin
        for i in 0 to 15 loop
            write(output, std_logic_to_string(a(i)));
        end loop;
    end procedure writer16;

    function to_string(x: string) return string is
        variable ret_val: string(1 to x'length);
        alias lx : string (1 to x'length) is x;
    begin  
        ret_val := lx;
        return(ret_val);
    end to_string;

    function to_std_logic_vector(x: bit_vector) return std_logic_vector is
        alias lx: bit_vector(1 to x'length) is x;
        variable ret_val: std_logic_vector(1 to x'length);
     begin
        for I in 1 to x'length loop
           if(lx(I) = '1') then
             ret_val(I) := '1';
           else
             ret_val(I) := '0';
           end if;
        end loop; 
        return ret_val;
     end to_std_logic_vector;

     function to_bit_vector(x: std_logic_vector) return bit_vector is
        alias lx: std_logic_vector(1 to x'length) is x;
        variable ret_val: bit_vector(1 to x'length);
     begin
        for I in 1 to x'length loop
           if(lx(I) = '1') then
             ret_val(I) := '1';
           else
             ret_val(I) := '0';
           end if;
        end loop; 
        return ret_val;
     end to_bit_vector;

     function bit_to_std_logic(bit_val : bit) return std_logic is
        begin
          if bit_val = '0' then
            return '0';
          else
            return '1';
          end if;
        end function;

    function std_logic_to_bit(std_logic_val : std_logic) return bit is
        begin
            if std_logic_val = '0' then
            return '0';
            else
            return '1';
            end if;
        end function;
end package body dataTypeConverter;