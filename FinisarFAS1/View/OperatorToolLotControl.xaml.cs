using Common;
using FinisarFAS1.ViewModel;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Input;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for OpertorToolLotControl.xaml
    /// </summary>
    public partial class OperatorToolLotControl : UserControl
    {
        public OperatorToolLotControl()
        {
            InitializeComponent();
            Messenger.Default.Register<ReFocusMessage>(this, reFocusMsgHandler);
        }

        private void reFocusMsgHandler(ReFocusMessage msg)
        {
                Vm_FocusOnField(msg.textbox2Focus, null);
        }

        private void TextBox_KeyUp(object sender, KeyEventArgs e)
        {
            var uie = e.OriginalSource as UIElement;

            if (e.Key == Key.Enter)
            {
                e.Handled = true;
                uie.MoveFocus(new TraversalRequest(FocusNavigationDirection.Next));
            }
        }

        private void TextBox_GotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {
            var box = sender as TextBox;
            if (box != null)
            {
                //if (!string.IsNullOrWhiteSpace(_currentFocusElementName))
                //{
                //    var b = FindName(_currentFocusElementName);
                //    if (b != null)
                //    {
                //        TextBox box1 = b as TextBox;
                //        if (box1 != null)
                //        {
                //            var elm = FocusManager.GetFocusedElement(this);
                //            if (box1 != box && box1 != elm && !box1.IsFocused)
                //            {
                //                e.Handled = true;
                //                box1.Focus();
                //                return;
                //            }
                //        }
                //    }
                //}
                //else
                {
                    box.SelectAll();
                }
            }
        }

        private string _currentFocusElementName = string.Empty;
        private void Vm_FocusOnField(object sender, EventArgs e)
        {
            string field = sender.ToString();
            if (field != "Reinit")
            {
                _currentFocusElementName = sender.ToString();
                //if (!string.IsNullOrEmpty(_currentFocusElementName))
                //{
                //    Application.Current.Dispatcher.Invoke((Action)delegate
                //    {
                //        FrameworkElement elem = FindName(_currentFocusElementName) as FrameworkElement;
                //        if(elem!=null)
                //            elem.Focus();
                //    });
                //}
            }
            else
            {
                Application.Current.Dispatcher.Invoke((Action)delegate
                {
                    _currentFocusElementName = string.Empty;
                    OperatorField.Focus();
                });
            }
        }

        private void Control_GotFocus(object sender, RoutedEventArgs e)
        {

            e.Handled = true;
            if (e.OriginalSource.GetType().Name == "TextBox")
            {
                //if (!string.IsNullOrWhiteSpace(_currentFocusElementName))
                //{
                //    Application.Current.Dispatcher.Invoke((Action)delegate
                //    {
                //        TextBox box = FindName(_currentFocusElementName) as TextBox;
                //        box.Focus();
                //    });
                //}
            }
        }

        private void Control_Loaded(object sender, RoutedEventArgs e)
        {
            OperatorField.Focus();
            //if (this.DataContext != null)
            //{
            //    OperatorToolLotViewModel vm = DataContext as OperatorToolLotViewModel;
            //    if (vm != null)
            //    {
            //        vm.FocusOnInvalidTextBox += Vm_FocusOnField;
            //    }
            //}
        }

        private void Control_UnLoaded(object sender, RoutedEventArgs e)
        {
            // Messenger.Default.Send(new CancelTransactionMessage());
            //OperatorToolLotViewModel vm = DataContext as OperatorToolLotViewModel;
            //if (vm != null)
            //{
            //    vm.FocusOnInvalidTextBox -= Vm_FocusOnField;
            //}
        }

        private void TextBox_KeyEnterUpdate(object sender, KeyEventArgs e)
        {
            var uie = e.OriginalSource as UIElement;

            if (e.Key == Key.Enter)
            {
                TextBox tBox = (TextBox)sender;
                DependencyProperty prop = TextBox.TextProperty;

                BindingExpression binding = BindingOperations.GetBindingExpression(tBox, prop);
                if (binding != null) { binding.UpdateSource(); }

                e.Handled = true;
                uie.MoveFocus(new TraversalRequest(FocusNavigationDirection.Next));
            }
        }

        private void Button_GotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {
            if (!string.IsNullOrWhiteSpace(_currentFocusElementName))
            {
                var b = FindName(_currentFocusElementName);
                if (b != null)
                {
                    TextBox box1 = b as TextBox;
                    if (box1 != null)
                    {
                        if (!box1.IsFocused)
                        {
                            e.Handled = true;
                            box1.Focus();
                            return;
                        }
                    }
                }
            }
        }
    }
}
