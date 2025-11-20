'use client'

import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Fix for default marker icon
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})

interface Store {
  id: number
  name: string
  latitude: number
  longitude: number
}

export default function MapView() {
  const [stores, setStores] = useState<Store[]>([])
  const [loading, setLoading] = useState(true)

  // Default center: India (Delhi)
  const defaultCenter: [number, number] = [28.6139, 77.2090]

  useEffect(() => {
    // TODO: Fetch stores from API
    // For now, using mock data
    setTimeout(() => {
      setStores([
        { id: 1, name: 'Store 1', latitude: 28.6139, longitude: 77.2090 },
        { id: 2, name: 'Store 2', latitude: 28.7041, longitude: 77.1025 },
      ])
      setLoading(false)
    }, 500)
  }, [])

  if (loading) {
    return (
      <div className="w-full h-full flex items-center justify-center">
        <p>Loading stores...</p>
      </div>
    )
  }

  return (
    <div className="w-full h-full">
      <MapContainer
        center={defaultCenter}
        zoom={11}
        style={{ width: '100%', height: '100%' }}
        className="z-0"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {stores.map((store) => (
          <Marker
            key={store.id}
            position={[store.latitude, store.longitude]}
          >
            <Popup>
              <div>
                <h3 className="font-bold">{store.name}</h3>
                <p className="text-sm">
                  {store.latitude.toFixed(4)}, {store.longitude.toFixed(4)}
                </p>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  )
}
