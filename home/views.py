from django.shortcuts import render
from django.http import HttpResponse


def homepage(response):
    return render(response, "home/home_index.html") 
