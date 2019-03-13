using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace FinisarFAS1.Converters
{
    public class BooleanToVerticalConverter : IValueConverter
    {
        #region IValueConverter Members
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if ((value is bool) && targetType == typeof(VerticalAlignment))
            {
                bool visible = (bool)value;
                if (visible)
                    return VerticalAlignment.Top;
                return VerticalAlignment.Center;
            }
            else
            {
                throw new ArgumentException("Must be converting bool to VerticalAlignment.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
        #endregion
    }

    public class YesNoConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            string val = (string)value;
            string param = (string)parameter;

            if (string.IsNullOrEmpty(val))      // if the value is null or blank,
                return false; // (param == "Y");          // we return true only for the Unspecified radio button
            else
                return (val == param);
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if ((bool)value)        // if the radio button is checked, return the radio button parameter back to the property.
                return (string)parameter;
            else
                return false;
        }
    }

    public class StringNullOrEmptyToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return string.IsNullOrEmpty(value as string) ? Visibility.Collapsed : Visibility.Visible;
        }
        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return null;
        }
    }

    public class StringNullOrEmptyToHiddenConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return string.IsNullOrEmpty(value as string) ? Visibility.Hidden : Visibility.Visible;
        }
        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return null;
        }
    }

    public class StringToOppositeVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return string.IsNullOrEmpty(value as string) ? Visibility.Visible : Visibility.Collapsed;
        }
        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return null;
        }
    }

    public class StringToVisibleConverter : IValueConverter
    {
        #region IValueConverter Members

        // null or blank string will return hidden,  otherwise will return visible
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (targetType == typeof(Visibility))
            {
                bool hidden = string.IsNullOrEmpty((string)value);        // if the string is null or empty, return hidden
                if (hidden)
                    return Visibility.Collapsed;
                return Visibility.Visible;
            }
            else
            {
                throw new ArgumentException("Must be converting string to Visibility.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }

    public class BooleanToVisibleConverter : IValueConverter
    {
        #region IValueConverter Members

        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if ((value is bool) && targetType == typeof(Visibility))
            {
                bool visible = (bool)value;
                if (visible)
                    return Visibility.Visible;
                return Visibility.Hidden;
            }
            else
            {
                throw new ArgumentException("Must be converting bool to Visibility.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }

    public class OppositeBooleanToVisibleConverter : IValueConverter
    {
        #region IValueConverter Members

        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if ((value is bool) && targetType == typeof(Visibility))
            {
                bool visible = (bool)value;
                if (visible)
                    return Visibility.Hidden;
                return Visibility.Visible;
            }
            else
            {
                throw new ArgumentException("Must be converting bool to Visibility.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }

    public class OppositeBooleanToCollapsedConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if ((value is bool) && targetType == typeof(Visibility))
            {
                bool visible = (bool)value;
                if (!visible)
                    return Visibility.Visible;
                return Visibility.Collapsed;
            }
            else
            {
                throw new ArgumentException("Must be converting bool to Visibility.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToCollapsedConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            // Added 12/19/2013 MIK 
            if (value == null)
                return Visibility.Collapsed;
            if ((value is bool) && targetType == typeof(Visibility))
            {
                bool visible = (bool)value;
                if (!visible)
                    return Visibility.Collapsed;
                return Visibility.Visible;
            }
            else
            {
                throw new ArgumentException("Must be converting bool to Visibility.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToEnabledColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            //if ((value is bool) && targetType == typeof(System.Windows.Controls))
            //{
            //    bool visible = (bool)value;
            //    if (visible)
            //        return System.Drawing.Color.Black;
            return null; // System.Drawing.Color.Gray;
            //}
            //else
            //{
            //    throw new ArgumentException("Must be converting bool to System.Drawing.Color.");
            //}
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class PanelMarginConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value is double)
            {
                double width = (double)value;
                Thickness panelMarginThickness = new Thickness(width * -1, 0, 0, 0);
                return panelMarginThickness;
            }
            throw new NotImplementedException();
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class PanelDimensionsConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            double? totalWidth = 0;

            //Combine all the values passed to give a total width
            foreach (object o in values)
            {
                int current;
                bool parsed = int.TryParse(o.ToString(), out current);
                if (parsed)
                {
                    totalWidth += current;
                }
            }

            //ensure negative value for scolling left
            // totalWidth *= -1;
            return totalWidth;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToRedGreenColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value is bool) //&& targetType == typeof(Soli))
            {
                bool renewal = (bool)value;
                if (renewal)
                    return new SolidColorBrush(Colors.LimeGreen);
                return new SolidColorBrush(Colors.Red);
            }
            else
            {
                throw new ArgumentException("Must be converting bool to System.Drawing.Color.");
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    [ValueConversion(typeof(bool), typeof(bool))]
    public class InverseBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (targetType != typeof(bool))
                throw new InvalidOperationException("The target must be a boolean");
            return !(bool)value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotSupportedException();
        }

    }


}
