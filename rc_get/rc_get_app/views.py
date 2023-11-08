from django.shortcuts import render
from django.http import JsonResponse
import subprocess

def run_rc_data(request):
    try:
        result = subprocess.check_output(['python', '../rc_data.py'])
        return JsonResponse({'result': result})
    except Exception as e:
        return JsonResponse({'error': str(e)})