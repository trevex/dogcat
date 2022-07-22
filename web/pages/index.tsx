import type { NextPage } from 'next'
import dynamic from "next/dynamic";
import Head from 'next/head'

const Game = dynamic(() => import("../components/Game"), {
    ssr: false,
});

const Home: NextPage = () => {
    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>

            <Game width={800} height={600} gridSize={20} />
        </div>
    )
}

export default Home
