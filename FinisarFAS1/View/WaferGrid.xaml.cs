using Common;
using FinisarFAS1.ViewModel;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Threading;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for WaferGrid.xaml
    /// </summary>
    public partial class WaferGrid : UserControl
    {
        public WaferGrid()
        {
            InitializeComponent();

            Messenger.Default.Register<WafersConfirmedMessage>(this, WafersConfirmedHandler);
            Messenger.Default.Register<SelectedWafersInGridMessage>(this, SelectedWafersInGridHandler);
        }      

        private void SelectedWafersInGridHandler(SelectedWafersInGridMessage msg)
        {
            if (msg.wafers?.Count > 0)
                msg.wafers.ForEach(wafer => LoadPort1Grid.SelectedItems.Add(wafer));
        }

        private void WafersConfirmedHandler(WafersConfirmedMessage msg)
        {
            this.IsConfirmed = msg.Confirmed;
        }


        private void TextBox_GotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {
            var box = sender as TextBox;
            if (box != null)
                box.SelectAll();
        }      

        private void TextBox_KeyUp(object sender, KeyEventArgs e)
        {

        }

        public bool IsConfirmed { get; set; }

        public WaferGridViewModel gridViewModel
        {
            get
            {
                return this.DataContext as WaferGridViewModel;
            }
        }

        // This method updates the SelectedWafers in the mainvm so that it can be used for the up and down arrows
        private void DataGrid_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            // ... Get SelectedItems from DataGrid.
            var grid = sender as DataGrid;
            var selected = grid.SelectedItems;

            List<Wafer> selectedObjects = selected.OfType<Wafer>().ToList();

            gridViewModel.SelectedWafers = selectedObjects;
        }

        private void Control_Loaded(object sender, RoutedEventArgs e)
        {
            Messenger.Default.Send(new InitializeWafersMessage());
        }
    }
}
