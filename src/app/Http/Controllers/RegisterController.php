<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RegisterController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|string|max:100',
            'email'    => 'required|email|max:255',
            'name'     => 'nullable|string|max:255',
            'phone'    => 'nullable|string|max:20',
        ]);

        DB::table('registrations')->insert([
            'username'   => $validated['username'],
            'email'      => $validated['email'],
            'name'       => $validated['name'] ?? null,
            'phone'      => $validated['phone'] ?? null,
            'created_at' => now(),
        ]);

        return response()->json(['status' => 'registered'], 201);
    }
}
