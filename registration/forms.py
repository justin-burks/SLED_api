from django import forms
from lenses.models import Users
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User


class RegisterForm(UserCreationForm):
    email = forms.EmailField()

    class Meta:
        model = Users
        fields = ["username", "email", "password1", "password2", "affiliation"]

    def __init__(self, *args, **kwargs):
        super(UserCreationForm, self).__init__(*args, **kwargs)
        # self.fields['username'].widgets.attrs.update({'class', 'field-label'})
        self.fields['username'].widget.attrs['class'] = 'field-label'
        self.fields['password1'].widget.attrs['class'] = 'field-label-2'
