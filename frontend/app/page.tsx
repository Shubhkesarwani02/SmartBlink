'use client'

import { useState } from 'react'
import dynamic from 'next/dynamic'

// Dynamically import map component to avoid SSR issues with Leaflet
const MapView = dynamic(() => import('@/components/MapView'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-100">
      <p>Loading map...</p>
    </div>
  ),
})

export default function Home() {
  const [activeTab, setActiveTab] = useState<'map' | 'analytics' | 'optimize'>('map')

  return (
    <main className="flex min-h-screen flex-col">
      {/* Header */}
      <header className="bg-primary-600 text-white p-4 shadow-lg">
        <div className="container mx-auto">
          <h1 className="text-2xl font-bold">🎯 SmartBlink</h1>
          <p className="text-sm text-primary-100">Dark Store Placement Optimization</p>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white border-b">
        <div className="container mx-auto flex gap-4 p-4">
          <button
            onClick={() => setActiveTab('map')}
            className={`px-4 py-2 rounded-lg transition-colors ${
              activeTab === 'map'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            📍 Map View
          </button>
          <button
            onClick={() => setActiveTab('analytics')}
            className={`px-4 py-2 rounded-lg transition-colors ${
              activeTab === 'analytics'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            📊 Analytics
          </button>
          <button
            onClick={() => setActiveTab('optimize')}
            className={`px-4 py-2 rounded-lg transition-colors ${
              activeTab === 'optimize'
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            🔧 Optimize
          </button>
        </div>
      </nav>

      {/* Content */}
      <div className="flex-1 relative">
        {activeTab === 'map' && <MapView />}
        {activeTab === 'analytics' && (
          <div className="p-8">
            <h2 className="text-2xl font-bold mb-4">Analytics Dashboard</h2>
            <p className="text-gray-600">Coming soon: Demand heatmaps, coverage metrics, and performance analytics</p>
          </div>
        )}
        {activeTab === 'optimize' && (
          <div className="p-8">
            <h2 className="text-2xl font-bold mb-4">Location Optimization</h2>
            <p className="text-gray-600">Coming soon: AI-powered store placement recommendations</p>
          </div>
        )}
      </div>
    </main>
  )
}
