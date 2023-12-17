public class COMReader
{
    private static readonly BlockingCollection<byte[]> queue = new BlockingCollection<byte[]>();

    public static int Main()
    {
        using (var port = new SerialPort("COM1", 9600, Parity.None, 8, StopBits.One)
        {
            Handshake = Handshake.None,
            ReadTimeout = 1000,
            WriteTimeout = 1000
        })
        {
            port.Open();

            var consumer = new Consumer(queue);
            var buffer = new byte[256];
            Action startListen = null;
            var onResult = new AsyncCallback(result => OnResult(result, startListen, port, buffer));

            Task.Run(() => consumer.Start());

            startListen = () => 
            {
                port.BaseStream.BeginRead(buffer, 0, buffer.Length, onResult, null);
            };

            startListen();

            while (true && port.IsOpen)
            {
                // handle user's console window interaction.
            }

            queue.CompleteAdding();

            if (port.IsOpen)
            {
                port.Close();
            }
        }

        return 0;
    }

    private static void OnResult(IAsyncResult result, Action startListen, SerialPort port, byte[] buffer)
    {
        try
        {
            if (!port.IsOpen)
            {
                return;
            }

            var actualLength = port.BaseStream.EndRead(result);

            var received = new byte[actualLength];

            Buffer.BlockCopy(buffer, 0, received, 0, actualLength);

            queue.Add(received);
        }
        catch (IOException)
        {
            Console.WriteLine("I/O exception encountered. Closing.");
            port.Close();
            queue.CompleteAdding();
            return;
        }

        startListen();
    }
}


public class Consumer
{
    private const byte TerminatingCharacter = 10;

    private readonly BlockingCollection<byte[]> producer;

    private readonly List<byte> bytes = new List<byte>();

    public Consumer(BlockingCollection<byte[]> producer)
    {
        this.producer = producer;
    }

    public void Start()
    {
        Console.WriteLine("Start listening");

        foreach (var item in producer.GetConsumingEnumerable())
        {
            ProcessInput(item);
        }

        Console.WriteLine("Finish listening");
    }

    private void ProcessInput(byte[] input)
    {
        if (input == null || input.Length == 0)
        {
            return;
        }

        if (input[input.Length - 1] == TerminatingCharacter)
        {
            var message = Encoding.UTF8.GetString(bytes.Concat(input).ToArray());

            Console.WriteLine($"Message Received: {Environment.NewLine}{message}{Environment.NewLine}");

            bytes.Clear();
        }
        else
        {
            bytes.AddRange(input);
        }
    }
}





// while ($true) { $k = [console]::readkey($true); if($k.keychar -eq "q"){break}; write-host "$([byte]$k.keychar), $($k.key)" }