using Common;
using FinisarFAS1.View;
using GalaSoft.MvvmLight;
using GalaSoft.MvvmLight.Command;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace FinisarFAS1.ViewModel
{
    public class EmailViewModel : ViewModelBase
    {
        public EmailViewModel()
        {
            SendTo = "ZahirHague@Finisar.com";
            Subject = "Reset Host reason"; 
            EmailBody = "Lorem ipsum dolor amet typewriter deep v plaid lo-fi. Bicycle rights af mlkshk church-key prism PBR&B vinyl. Wolf heirloom four dollar toast, poke ennui brunch ramps mixtape vice humblebrag artisan. Retro ramps snackwave shaman church-key beard vape wayfarers shoreditch. ";
        }

        public EmailViewModel(string sendTo, string subject, string body)
        {
            SendTo = sendTo;
            Subject = subject;
            EmailBody = body; 
        }


        private string _sendTo;
        public string SendTo {
            get { return _sendTo; }
            set {
                _sendTo = value;
                RaisePropertyChanged(nameof(SendTo));
            }
        }

        private string _subject;
        public string Subject {
            get { return _subject; }
            set {
                _subject = value;
                RaisePropertyChanged(nameof(Subject));
            }
        }

        private string _emailBody;
        public string EmailBody {
            get { return _emailBody; }
            set {
                _emailBody = value;
                RaisePropertyChanged(nameof(EmailBody));
            }
        }

        public ICommand CancelCmd => new RelayCommand(cancelHandler);
        public ICommand SendEmailCmd => new RelayCommand(sendEmailHandler);

        private void cancelHandler()
        {
            SendTo = Subject = EmailBody = ""; 
            Messenger.Default.Send(new CloseAndSendEmailMessage(SendTo, Subject, EmailBody));
        }

        private void sendEmailHandler()
        {
            Messenger.Default.Send(new CloseAndSendEmailMessage(SendTo, Subject, EmailBody));
        }
    }
}
