
namespace Common
{
    public class Operator
    {
        public Operator()
        {
            Id = 0;
            AuthLevel = AuthorizationLevel.InvalidUser;
            OperatorName = "";
            OperatorInfo = "";
        }

        public int Id { get; set; }
        public AuthorizationLevel AuthLevel { get; set; }
        public string OperatorName { get; set; }
        public string OperatorInfo { get; set; }
    }

    public enum AuthorizationLevel
    {
        InvalidUser,
        Operator, 
        Engineer, 
        Administrator
    }

}
