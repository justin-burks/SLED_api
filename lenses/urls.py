from django.urls import path

from . import views


app_name = 'lenses'
urlpatterns = [
    path('', views.index, name='index'),
]