using FinisarFAS1.Utility;
using GalaSoft.MvvmLight.Command;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace FinisarFAS1.ViewModel
{
    public class DialogViewModel : IDialogRequestClose
    {
        public string TitleText { get; private set; }
        public string Message { get; private set; }
        public string YesText { get; private set; }
        public string CancelText { get; private set; }


        public DialogViewModel(string message, string yes, string cancel)
        {
            Message = message;
            YesText = yes;
            CancelText = cancel;
            TitleText = "Confirm Action";
            OkCommand = new RelayCommand( () => CloseRequested?.Invoke(this, new DialogCloseRequestedEventArgs(true)));
            CancelCommand = new RelayCommand( () => CloseRequested?.Invoke(this, new DialogCloseRequestedEventArgs(false)));
        }

        public event EventHandler<DialogCloseRequestedEventArgs> CloseRequested;
        public ICommand OkCommand { get; }
        public ICommand CancelCommand { get; }
    }
}
