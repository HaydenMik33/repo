using System;
using System.Collections.Generic;
using System.Windows;

namespace FinisarFAS1.Utility
{
    public interface IDialog
    {
        object DataContext { get; set; }
        bool? DialogResult { get; set; }
        Window Owner { get; set; }
        void Close();
        bool? ShowDialog();
    }

    public interface IDialogService2
    {
        void Register<TViewModel, TView>() 
            where TViewModel : IDialogRequestClose
            where TView : IDialog;

        bool? ShowDialog<TViewModel>(TViewModel viewModel) where TViewModel : IDialogRequestClose;
    }

    public interface IDialogRequestClose
    {
        event EventHandler<DialogCloseRequestedEventArgs> CloseRequested; 
    }

    public class DialogCloseRequestedEventArgs : EventArgs
    {
        public DialogCloseRequestedEventArgs(bool? dialogResult)
        {
            DialogResult = dialogResult;
        }
        public bool? DialogResult { get; set; }
    }

    public class MyDialogService : IDialogService2
    {
        private readonly Window owner;

        public IDictionary<Type, Type> Mappings { get; private set; }

        public MyDialogService(Window owner)
        {
            this.owner = owner;
            Mappings = new Dictionary<Type, Type>(); 
        }

        public void Register<TViewModel, TView>()
            where TViewModel : IDialogRequestClose
            where TView : IDialog
        {
            if (Mappings.ContainsKey(typeof(TViewModel)))
            {
                throw new ArgumentException($"Type {typeof(TViewModel)} is already mapped to type {typeof(TView)}");
            }
            Mappings.Add(typeof(TViewModel), typeof(TView));
        }

        public bool? ShowDialog<TViewModel>(TViewModel viewModel) where TViewModel : IDialogRequestClose
        {
            Type viewType = Mappings[typeof(TViewModel)];
            IDialog dialog = (IDialog)Activator.CreateInstance(viewType);
            EventHandler<DialogCloseRequestedEventArgs> handler = null;

            handler = (sender, e) =>
            {
                viewModel.CloseRequested -= handler;
                if (e.DialogResult.HasValue)
                {
                    dialog.DialogResult = e.DialogResult;
                }
                else
                {
                    dialog.Close();
                }
            };

            viewModel.CloseRequested += handler;

            dialog.DataContext = viewModel;
            dialog.Owner = owner;
            return dialog.ShowDialog(); 
        }
    }
}
