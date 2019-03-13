using FinisarFAS1.ViewModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for EmailView.xaml
    /// </summary>
    public partial class EmailView : Window
    {
        public EmailView()
        {
            InitializeComponent();
        }

        private void SendEmail_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = true; 
        }
    }
}
