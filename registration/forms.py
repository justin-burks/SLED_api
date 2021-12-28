from django import forms
from lenses.models.user import Users
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm, UsernameField
from django.contrib.auth.models import User

class RegisterForm(UserCreationForm):
    email = forms.EmailField()

    class Meta:
        model = Users
        fields = ["username", "email", "password1", "password2", "affiliation"]

    def __init__(self, *args, **kwargs):
        super(UserCreationForm, self).__init__(*args, **kwargs)
        # self.fields['username'].widgets.attrs.update({'class', 'field-label'})
        self.fields['username'].widget.attrs['class'] = 'text-field w-input'
        self.fields['email'].widget.attrs['class'] = 'text-field w-input'
        self.fields['password1'].widget.attrs['class'] = 'text-field w-input'
        self.fields['password2'].widget.attrs['class'] = 'text-field w-input'
        self.fields['affiliation'].widget.attrs['class'] = 'text-field w-input'



class UserLoginForm(AuthenticationForm):

    class Meta:
        model = Users
        fields = ["username", "password"]

    def __init__(self, *args, **kwargs):
        super(UserLoginForm, self).__init__(*args, **kwargs)
        self.fields['username'].widget.attrs['class'] = 'text-field w-input'
        self.fields['password'].widget.attrs['class'] = 'text-field w-input'
