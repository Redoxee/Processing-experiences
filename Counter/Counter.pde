String savePath = "CounterSave";

void setup()
{
    int counter = Increment(savePath);
    println("Output " + counter);
    println("To hex " + ToHex(counter));
    exit();
}

int GetCount(String fileName)
{
    String[] strings = loadStrings(fileName);
    return int(strings[0]);
}

int Increment(String fileName)
{
    int count = GetCount(fileName);
    PrintWriter output = createWriter(fileName);
    output.print(count + 1);
    output.close();
    return count;
}

String ToHex(int input)
{
    String charTable = "0123456789ABCDEF";
    String result = "";
    do
    {
        int rest = input % 16;
        result = charTable.charAt(rest) + result;
        input /= 16;
    }while(input > 0);

    return result;
}