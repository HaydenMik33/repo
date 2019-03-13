using SECSInterface;

namespace ToolService
{
    public class SVID
    {
        public int Id { get; set; }
        public DataType Type { get; set; } = DataType.UI4;
        public SECSData SecsData { get; set; }

    }
}