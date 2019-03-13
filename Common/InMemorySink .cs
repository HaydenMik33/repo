using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Serilog;
using Serilog.Formatting;
using Serilog.Core;
using Serilog.Formatting.Display;
using System.Collections.Concurrent;
using Serilog.Events;
using System.IO;
using System.Globalization;

namespace Common
{
    public class InMemorySink : ILogEventSink
    {
        readonly ITextFormatter _textFormatter = new MessageTemplateTextFormatter("{Timestamp} [{Level}] {Message}{Exception}", new CultureInfo("en-US"));

        public ConcurrentQueue<string> Events { get; } = new ConcurrentQueue<string>();

        public void Emit(LogEvent logEvent)
        {
            if (logEvent == null) throw new ArgumentNullException(nameof(logEvent));
            var renderSpace = new StringWriter();
            _textFormatter.Format(logEvent, renderSpace);
            Events.Enqueue(renderSpace.ToString());
        }

        static void Main(string[] args)
        {
            var sink = new InMemorySink();
            Log.Logger = new LoggerConfiguration()
                .WriteTo.Sink(sink)
                .WriteTo.File("testDir",
                    rollingInterval: RollingInterval.Day,
                    rollOnFileSizeLimit: true)
                .CreateLogger();

            Log.Information("test log message");
        }
    }

    
}
